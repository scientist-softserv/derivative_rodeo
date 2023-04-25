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

      attr_accessor :input_uris, :output_adapter_name, :output_extension, :generated_files

      def initialize(input_uris:, output_adapter_name: 'same')
        @input_uris = input_uris
        @output_adapter_name = output_adapter_name
        raise MissingOutputExtension, self.class unless output_extension
      end

      def build
        self.generated_files = input_files.map do |file|
          new_file = build_step(file)
          new_file.file_uri
        end
      end

      def build_step(file)
        raise NotImplementedError
      end
    end
  end
end
