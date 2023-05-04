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
    # - may override {#requisite_files}
    class BaseGenerator
      class_attribute :output_extension

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
      # When the output adapter is the same type of adapter as "this" adapter, we indicate that via
      # the SAME constant.
      SAME = 'same'

      ##
      # TODO: rename preprocess adapter because it is the same as the preprocess method, but does
      # something else
      #
      # @raise [Errors::ExtensionMissingError] when we have not properly assigned the
      #        {.output_extension}
      def initialize(input_uris:, output_adapter_name: SAME, preprocess_adapter_name: nil, logger: DerivativeRodeo.config.logger)
        @input_uris = input_uris
        @output_adapter_name = output_adapter_name
        @preprocess_adapter_name = preprocess_adapter_name
        @logger = logger

        # When we have a BaseGenerator and not one of it's children or when we've assigned the
        # output_extension.  instance_of? is more specific than is_a?
        return if instance_of?(DerivativeRodeo::Generators::BaseGenerator) || output_extension

        raise Errors::ExtensionMissingError.new(klass: self.class)
      end

      ##
      # @param in_file [StorageAdapters::BaseAdapter]
      # @param out_file [StorageAdapters::BaseAdapter]
      #
      # @return [StorageAdapters::BaseAdapter]
      def build_step(in_file:, out_file:)
        raise NotImplementedError, "#{self.class}#build_step"
      end

      ##
      # @return [Array<StorageAdapters::BaseAdapter>]
      def generated_files
        @generated_files ||= requisite_files.map do |file|
          output_file = destination(file)
          new_file = output_file.exist? ? output_file : build_step(in_file: file, out_file: output_file)
          new_file
        end
      end

      ##
      # @return [Array<String>]
      def generated_uris
        generated_files.map { |file| file&.file_uri }
      end

      ##
      # @api public
      #
      # The files that are required as part of the {#generated_files} (though more precisely the
      # {#build_step}.)
      #
      # This method allows child classes to modify the file_uris for example, to filter out files
      # that are not of the correct type or as a means of having "this" generator depend on another
      # generator.
      #
      # @return [Array<StorageAdapters::BaseAdapter>]
      #
      # @see HocrGenerator
      # @see #generated_files
      def requisite_files
        input_files
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
      # @return [StorageAdapters::BaseAdapter] the derivative of the given :file with the configured
      #         :output_extension
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
