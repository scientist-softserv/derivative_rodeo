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

      attr_accessor :input_uris, :output_adapter_name, :output_extension, :generated_files, :exception

      def initialize(input_uris:, output_adapter_name: 'same')
        @input_uris = input_uris
        @output_adapter_name = output_adapter_name
        @output_extension = self.class.output_extension
        return if instance_of?(DerivativeZoo::Generator::BaseGenerator) || output_extension

        raise DerivativeZoo::ExtensionMissingError.new(klass: self.class)
      end

      def build_step(in_file:, out_file:)
        raise NotImplementedError
      end

      def build
        self.generated_files = input_files.map do |file|
          output_file = destination(file)
          new_file = output_file.exist? ? output_file : build_step(in_file: file, out_file: output_file)
          new_file&.file_uri
        end
      end

      def input_files
        @input_files ||= input_uris.map do |file_uri|
          DerivativeZoo::StorageAdapter::BaseAdapter.from_uri(file_uri)
        end
      end

      def destination(file)
        file.derived_file(extension: output_extension,
                          adapter_name: output_adapter_name)
      end
    end
  end
end
