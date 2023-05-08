# frozen_string_literal: true
require 'derivative_rodeo/generators/concerns/copy_file_concern'

module DerivativeRodeo
  module Generators
    ##
    # Responsible for moving files from one storage adapter to another.
    class CopyGenerator < BaseGenerator
      self.output_extension = StorageAdapters::SAME

      include CopyFileConcern

      # rubocop:disable Lint/MissingSuper --- A Temporary solution until I refactor all of the other generators.
      def initialize(input_uris:, output_target_template: "{{ scheme }}://{{ dir_parts[0..-1] }}/filename", preprocess_adapter_name: nil, logger: DerivativeRodeo.config.logger)
        @input_uris = input_uris
        @output_target_template = output_target_template
        @preprocess_adapter_name = preprocess_adapter_name
        @logger = logger

        return if valid_instantiation?

        raise Errors::ExtensionMissingError.new(klass: self.class)
      end
      # rubocop:enable Lint/MissingSuper --- A Temporary solution until I refactor all of the other generators.

      attr_reader :output_target_template

      ##
      # Checks for file at destination and checks in prefetch location if not
      #
      # @param file [StorageAdapters::BaseAdapter]
      #
      # @return [StorageAdapters::BaseAdapter] the derivative of the given :file with the configured
      #         {.output_extension}
      # @see .output_extension
      def destination(file)
        dest = file.derived_file_from(template: output_target_template)

        pre_dest = if !dest.exist? && preprocess_adapter_name
                     file.derived_file(extension: output_extension,
                                       adapter_name: preprocess_adapter_name)
                   end
        dest = pre_dest if pre_dest&.exist?
        dest
      end
    end
  end
end
