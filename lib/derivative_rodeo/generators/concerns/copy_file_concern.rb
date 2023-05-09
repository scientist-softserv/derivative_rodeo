# frozen_string_literal: true
module DerivativeRodeo
  module Generators
    ##
    # A helper module for copying files from one location to another.
    module CopyFileConcern
      ##
      # @param input_uris [Array<String>]
      # @param output_target_template [String]
      # @param preprocess_adapter_name [String]
      # @param logger [Logger]
      def initialize(input_uris:, output_target_template:, preprocess_adapter_name: nil, logger: DerivativeRodeo.config.logger)
        @input_uris = input_uris
        @output_target_template = output_target_template
        @preprocess_adapter_name = preprocess_adapter_name
        @logger = logger

        return if valid_instantiation?

        raise Errors::ExtensionMissingError.new(klass: self.class)
      end

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

      ##
      # Copy files from one adapter to another.
      #
      # @param out_file [StorageAdapters::BaseAdapter]
      # @param in_tmp_path [String]
      #
      # @return [StorageAdapters::BaseAdapter]
      def build_step(out_file:, in_tmp_path:, **)
        copy(in_tmp_path, out_file)
      end

      ##
      # @api private
      def copy(_from_path, out_file)
        out_file.with_new_tmp_path do |_out_path|
          # This space deliberately left blank; we need to pass a block for all of the magic to
          # happen.
        end
        out_file
      end
    end
  end
end
