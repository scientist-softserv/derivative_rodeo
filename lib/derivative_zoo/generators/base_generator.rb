# frozen_string_literal: true

module DerivativeZoo
  ##
  # Generators execute a transofrmatoin on files and return new files
  # A generator class must set an output extention and must implement
  # a build_step method
  module Generator
    ##
    # Base Generator, defines interface and common methods
    class BaseGenerator
      class_attribute :output_extension

      attr_accessor :exception,
        :input_uris,
        :output_adapter_name,
        :output_extension,
        :preprocess_adapter_name
      attr_writer :generated_files

      def initialize(input_uris:, output_adapter_name: 'same', preprocess_adapter_name: nil)
        @input_uris = input_uris
        @output_adapter_name = output_adapter_name
        @output_extension = self.class.output_extension
        @preprocess_adapter_name = preprocess_adapter_name
        return if instance_of?(DerivativeZoo::Generator::BaseGenerator) || output_extension

        raise DerivativeZoo::ExtensionMissingError.new(klass: self.class)
      end

      def build_step(in_file:, out_file:)
        raise NotImplementedError
      end

      def generated_files
        @generated_files ||= preprocess.map do |file|
          output_file = destination(file)
          new_file = output_file.exist? ? output_file : build_step(in_file: file, out_file: output_file)
          new_file
        end
      end

      def generated_uris
        generated_files.map { |file| file&.file_uri }
      end

      ##
      # Preprocess is run before the build step. It allows child classes to modify the file_uirs
      # for example, to filter out files that are not of the correct type or to depend on another
      # generator. See DerivativeZoo::Generator::HocrGenerator for an example
      #
      # @api public
      #
      # @return [Array<String>] the file_uris
      def preprocess
        input_files
      end

      def input_files
        @input_files ||= input_uris.map do |file_uri|
          DerivativeZoo::StorageAdapter::BaseAdapter.from_uri(file_uri)
        end
      end

      def destination(file)
        dest = if preprocess_adapter_name
                 file.derived_file(extension: output_extension,
                                   adapter_name: preprocess_adapter_name)
               end
        return dest if dest&.exist?
        file.derived_file(extension: output_extension,
                          adapter_name: output_adapter_name)
      end

      ##
      # A bit of indirection to create a common interface for running a shell command; and thus
      # allowing for introducing a dry-run to help in debugging/logging.
      #
      # @param command [String]
      #
      # @note
      #
      def run(command)
        DerivativeZoo.config.logger.debug "* Start command: #{command}"
        result = `#{command}`
        DerivativeZoo.config.logger.debug "* Result: \n*  #{result.gsub("\n", "\n*  ")}"
        DerivativeZoo.config.logger.debug "* End  command: #{command}"
        result
      end
    end
  end
end

Dir.glob(File.join(__dir__, '**/*')).sort.each do |file|
  require file unless File.directory?(file) || file.match?(/base_generator/)
end
