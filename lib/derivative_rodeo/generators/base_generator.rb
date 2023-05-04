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
    # - may override {#with_each_requisite_file_and_tmp_path}
    class BaseGenerator
      ##
      # @!group Class Attributes
      # @!attribute [rw]
      #
      # @return [String] of the form that starts with a string and may contain periods (though
      #         likely not as the first character).
      class_attribute :output_extension
      # @!endgroup Class Attributes

      # TODO: Add the registered generators?  This seems like a nice pattern to carry forward from
      # the BaseAdapter

      # TODO: Why do we have an :exception?
      # TODO: Can these be attr_reader instead?
      attr_accessor :exception,
                    :input_uris,
                    :output_adapter_name,
                    :preprocess_adapter_name

      # TODO: Why do we have this writer?
      attr_writer :generated_files
      attr_reader :logger

      ##
      # TODO: rename preprocess adapter because it is the same as the preprocess method, but does
      # something else
      #
      # @example
      #
      #   .new(input_uris: ["file:///path1/A/file.pdf", "file:///path2/B/file.pdf"],
      #        output_target_template: "file:///dest1/{{path_parts[-2..-1]}}",
      #        preprocessed_target_template: "s3://bucket_name/{{path_parts[-1..-1]}}")
      #
      #   => { output_uris: ["file:///dest1/A/file.pdf", "file:///dest2/B/file.pdf"]
      #        preprocess_url: "s3://bucket_name/file.pdf" }
      #
      #  (Look to handlebars gem)
      #
      # @raise [Errors::ExtensionMissingError] when we have not properly assigned the
      #        {.output_extension}
      def initialize(input_uris:, output_adapter_name: StorageAdapters::SAME, preprocess_adapter_name: nil, logger: DerivativeRodeo.config.logger)
        @input_uris = input_uris
        @output_adapter_name = output_adapter_name
        @preprocess_adapter_name = preprocess_adapter_name
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
      # @param in_file [StorageAdapters::BaseAdapter] the input source of the generation
      # @param out_file [StorageAdapters::BaseAdapter] the output target of the generation
      # @param in_tmp_path [String] the temporary path to the location of the given :in_file to
      #        enable further processing on the file.
      #
      # @return [StorageAdapters::BaseAdapter]
      # @see #generated_files
      def build_step(in_file:, out_file:, in_tmp_path:)
        raise NotImplementedError, "#{self.class}#build_step"
      end

      ##
      # @api public
      #
      # @return [Array<StorageAdapters::BaseAdapter>]
      #
      # @see #build_step
      # @see #with_each_requisite_file_and_tmp_path
      def generated_files
        return @generated_files if defined?(@generated_files)

        # As much as I would like to use map or returned values; given the implementations it's
        # better to explicitly require that; reducing downstream implementation headaches.
        #
        # In other words, this little bit of ugly in a method that has yet to change in a subclass
        # helps ease subclass implementations of the #with_each_requisite_file_and_tmp_path or
        # #build_step
        @generated_files = []
        with_each_requisite_file_and_tmp_path do |file, tmp_path|
          generated_file = destination(file)
          @generated_files << if generated_file.exist?
                                generated_file
                              else
                                build_step(in_file: file, out_file: generated_file, in_tmp_path: tmp_path)
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
      # This method is responsible for two things:
      #
      # - returning an array of {StorageAdapters::BaseAdapter} objects
      # - yielding a {#StorageAdapters::BaseAdapter} and the path (as String) to the files
      #   location in the temporary working space.
      #
      # This method allows child classes to modify the file_uris for example, to filter out files
      # that are not of the correct type or as a means of having "this" generator depend on another
      # generator.
      #
      # @yieldparam file [StorageAdapters::BaseAdapters] the file and adapter logic.
      # @yieldparam tmp_path [String] where to find this file in the tmp space
      #
      # @see Generators::HocrGenerator
      # @see Generators::PdfSplitGenerator
      def with_each_requisite_file_and_tmp_path
        input_files.each do |input_file|
          input_file.with_existing_tmp_path do |tmp_path|
            yield(input_file, tmp_path)
          end
        end
      end

      ##
      # @return [Array<StorageAdapters::BaseAdapter>]
      def input_files
        @input_files ||= input_uris.map do |file_uri|
          DerivativeRodeo::StorageAdapters::BaseAdapter.from_uri(file_uri)
        end
      end

      ##
      # Checks for file at destination and checks in prefetch location if not
      #
      # @param file [StorageAdapters::BaseAdapter]
      #
      # @return [StorageAdapters::BaseAdapter] the derivative of the given :file with the configured
      #         {.output_extension}
      # @see .output_extension
      def destination(file)
        dest = file.derived_file(extension: output_extension,
                                 adapter_name: output_adapter_name)

        pre_dest = if !dest.exist? && preprocess_adapter_name
                     file.derived_file(extension: output_extension,
                                       adapter_name: preprocess_adapter_name)
                   end
        dest = pre_dest if pre_dest&.exist?
        dest
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
