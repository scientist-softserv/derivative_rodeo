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
    # - must an {.output_extension=}
    # - must impliment a {#build_step} method
    class BaseGenerator
      class_attribute :output_extension

      # TODO: Add the registered generators?  This seems like a nice pattern to carry forward from
      # the BaseAdapter

      attr_accessor :exception,
        :input_uris,
        :output_adapter_name,
        :output_extension,
        :preprocess_adapter_name
      attr_writer :generated_files

      ##
      # TODO: rename preprocess adapter because it is the same as the preprocess method, but does
      # something else
      #
      # TODO: Remove magic 'same' and document it's purpose
      def initialize(input_uris:, output_adapter_name: 'same', preprocess_adapter_name: nil, logger: DerivativeRodeo.config.logger)
        @input_uris = input_uris
        @output_adapter_name = output_adapter_name
        @output_extension = self.class.output_extension
        @preprocess_adapter_name = preprocess_adapter_name
        @logger = logger

        return if instance_of?(DerivativeRodeo::Generators::BaseGenerator) || output_extension

        raise Errors::ExtensionMissingError.new(klass: self.class)
      end

      attr_reader :logger

      def build_step(in_file:, out_file:)
        raise NotImplementedError, "#{self.class}#build_step"
      end

      def generated_files
        @generated_files ||= requisite_files.map do |file|
          output_file = destination(file)
          new_file = output_file.exist? ? output_file : build_step(in_file: file, out_file: output_file)
          new_file
        end
      end

      def generated_uris
        generated_files.map { |file| file&.file_uri }
      end

      ##
      # requisite_files is run before the build step. It allows child classes to modify the file_uirs
      # for example, to filter out files that are not of the correct type or to depend on another
      # generator. See DerivativeRodeo::Generator::HocrGenerator for an example
      #
      # @api public
      #
      # @return [Array<String>] the file_uris
      def requisite_files
        input_files
      end

      def input_files
        @input_files ||= input_uris.map do |file_uri|
          DerivativeRodeo::StorageAdapters::BaseAdapter.from_uri(file_uri)
        end
      end

      # checks for file at destination and checks in prefetch location if not
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
      def run(command)
        logger.debug "* Start command: #{command}"
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
