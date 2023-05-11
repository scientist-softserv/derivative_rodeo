# frozen_string_literal: true

module DerivativeRodeo
  ##
  # Generators execute a transformation on files and return new files.
  #
  # A new generator should inherit from {BaseGenerator}.
  #
  # @see BaseGenerator
  module Generators
    ##
    # The Base Generator defines the interface and common methods.
    #
    # In extending a BaseGenerator you:
    #
    # - must assign an {.output_extension}
    # - must impliment a {#build_step} method
    # - may override {#with_each_requisite_target_and_tmp_file_path}
    class BaseGenerator
      ##
      # @!group Class Attributes
      # @!attribute [rw]
      #
      # @return [String] of the form that starts with a string and may contain periods (though
      #         likely not as the first character).
      class_attribute :output_extension
      # @!endgroup Class Attributes

      attr_reader :input_uris,
                  :logger,
                  :output_target_template,
                  :preprocessed_target_template

      ##
      # @param input_uris [Array<String>]
      # @param output_target_template [String] the template used to transform the given :input_uris
      #        via {Services::ConvertUriViaTemplateService}.
      # @param preprocessed_target_template [NilClass, String] when `nil` ignore, otherwise attempt
      #        to find preprocessed uris by transforming the :input_uris via
      #        {Services::ConvertUriViaTemplateService} with the given
      #        :preprocessed_target_template.
      # @param logger [Logger]
      def initialize(input_uris:, output_target_template:, preprocessed_target_template: nil, logger: DerivativeRodeo.config.logger)
        @input_uris = input_uris
        @output_target_template = output_target_template
        @preprocessed_target_template = preprocessed_target_template
        @logger = logger

        return if valid_instantiation?

        raise Errors::ExtensionMissingError.new(klass: self.class)
      end

      ##
      # @api private
      #
      # @return [Boolean]
      def valid_instantiation?
        # When we have a BaseGenerator and not one of it's children or when we've assigned the
        # output_extension.  instance_of? is more specific than is_a?
        instance_of?(DerivativeRodeo::Generators::BaseGenerator) || output_extension
      end

      ##
      # @api public
      #
      # @param input_target [StorageTargets::BaseTarget] the input source of the generation
      # @param to_target [StorageTargets::BaseTarget] the output target of the generation
      # @param from_tmp_path [String] the temporary path to the location of the given :input_target to
      #        enable further processing on the file.
      #
      # @return [StorageTargets::BaseTarget]
      # @see #generated_files
      def build_step(input_target:, to_target:, from_tmp_path:)
        raise NotImplementedError, "#{self.class}#build_step"
      end

      ##
      # @api public
      #
      # @return [Array<StorageTargets::BaseTarget>]
      #
      # @see #build_step
      # @see #with_each_requisite_target_and_tmp_file_path
      def generated_files
        return @generated_files if defined?(@generated_files)

        # As much as I would like to use map or returned values; given the implementations it's
        # better to explicitly require that; reducing downstream implementation headaches.
        #
        # In other words, this little bit of ugly in a method that has yet to change in a subclass
        # helps ease subclass implementations of the #with_each_requisite_target_and_tmp_file_path or
        # #build_step
        @generated_files = []
        with_each_requisite_target_and_tmp_file_path do |input_target, tmp_file_path|
          generated_file = destination(input_target)
          @generated_files << if generated_file.exist?
                                generated_file
                              else
                                build_step(input_target: input_target, to_target: generated_file, from_tmp_path: tmp_file_path)
                              end
        end
        @generated_files
      end

      ##
      # @return [Array<String>]
      # @see #generated_files
      def generated_uris
        # TODO: what do we do about nils?
        generated_files.map { |file| file&.file_uri }
      end

      ##
      # @api public
      #
      # The files that are required as part of the {#generated_files} (though more precisely the
      # {#build_step}.)
      #
      # This method is responsible for one thing:
      #
      # - yielding a {StorageTargets::BaseTarget} and the path (as String) to the files
      #   location in the temporary working space.
      #
      # This method allows child classes to modify the file_uris for example, to filter out files
      # that are not of the correct type or as a means of having "this" generator depend on another
      # generator.  The {Generators::HocrGenerator} requires that the input_target be a monochrome;
      # so it does conversions of each given input_target.  The {Generators::PdfSplitGenerator} uses
      # this method to take each given PDF and generated one image per page of each given PDF.
      # Those images are then treated as the requisite targets.
      #
      # @yieldparam input_target [StorageTargets::BaseTargets] the from target as represented by
      #             a URI.
      # @yieldparam tmp_file_path [String] where to find the input_target's file in the processing tmp
      #             space.
      #
      # @see Generators::HocrGenerator
      # @see Generators::PdfSplitGenerator
      def with_each_requisite_target_and_tmp_file_path
        input_files.each do |input_target|
          input_target.with_existing_tmp_path do |tmp_file_path|
            yield(input_target, tmp_file_path)
          end
        end
      end

      ##
      # @return [Array<StorageTargets::BaseTarget>]
      def input_files
        @input_files ||= input_uris.map do |file_uri|
          DerivativeRodeo::StorageTargets::BaseTarget.from_uri(file_uri)
        end
      end

      ##
      # Returns the target destination for the given :input_file.  The file at the target
      # destination might exist or might not.  In the case of non-existence, then the {#build_step}
      # will create the file.
      #
      # @param input_target [StorageTargets::BaseTarget]
      #
      # @return [StorageTargets::BaseTarget] the derivative of the given :file based on either the
      #         {#output_target_template} or {#preprocessed_target_template}.
      #
      # @see [StorageTargets::BaseTarget#exist?]
      def destination(input_target)
        output_target = input_target.derived_file_from(template: output_target_template)

        return output_target if output_target.exist?
        return output_target unless preprocessed_target_template

        preprocessed_target = input_target.derived_file_from(template: preprocessed_target_template)
        # We only want
        return preprocessed_target if preprocessed_target&.exist?

        # NOTE: The file does not exist at the output_target; but we pass this information along so
        # that the #build_step knows where to write the file.
        output_target
      end

      ##
      # A bit of indirection to create a common interface for running a shell command.
      #
      # @param command [String]
      # @return [String]
      def run(command)
        logger.debug "* Start command: #{command}"
        # TODO: What kind of error handling do we want?
        result = `#{command}`
        logger.debug "* Result: \n*  #{result.gsub("\n", "\n*  ")}"
        logger.debug "* End  command: #{command}"
        result
      end
    end
  end
end

Dir.glob(File.join(__dir__, '**/*')).sort.each do |file|
  require file unless File.directory?(file) || file.match?(/base_generator/)
end
