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
        @generated_files ||= with_requisite_files do |file, tmp_path|
          output_file = destination(file)
          new_file = output_file.exist? ? output_file : build_step(in_file: file, out_file: output_file, in_tmp_path: tmp_path)
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

      def with_requisite_files
        input_files.map do |input_file|
          input_file.with_existing_tmp_path do |tmp_path|
            yield(input_file, tmp_path)
          end
          input_file
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
      # @param extension [String] the target extension for the given :file.
      # @return [StorageAdapters::BaseAdapter] the derivative of the given :file with the configured
      #         :output_extension
      # @see .output_extension
      def destination(file, extension: extension_for(file))
        dest = file.derived_file(extension: extension,
                                 adapter_name: output_adapter_name)

        pre_dest = if !dest.exist? && preprocess_adapter_name
                     file.derived_file(extension: extension,
                                       adapter_name: preprocess_adapter_name)
                   end
        dest = pre_dest if pre_dest&.exist?
        dest
      end

      ##
      # By default return {.output_extension}; this is provided to account for the antics of the
      # {Generators::CopyGenerator}.  How can one know what the extension is, because we are
      # likely not going to copy `file://path/to/file.txt` to
      # `file://elsewhere/path/to/file.txt.copy`
      #
      # @param _file [StorageAdapters::BaseAdapter]
      # @return [String]
      #
      # @see output_extension
      def extension_for(_file)
        output_extension
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
