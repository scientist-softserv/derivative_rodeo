# frozen_string_literal: true

module DerivativeRodeo
  module Generators
    ##
    # Take images an ensures that we have a monochrome derivative of those images.
    class MonochromeGenerator < BaseGenerator
      # TODO: Can we assume a tiff?
      self.output_extension = 'mono.tiff'

      ##
      # @param input_uris [Array<String>]
      # @param output_target_template [String]
      # @param preprocess_adapter_name [String]
      # @param logger [Logger]
      #
      # rubocop:disable Lint/MissingSuper
      def initialize(input_uris:, output_target_template:, preprocess_adapter_name: nil, logger: DerivativeRodeo.config.logger)
        @input_uris = input_uris
        @output_target_template = output_target_template
        @preprocess_adapter_name = preprocess_adapter_name
        @logger = logger

        return if valid_instantiation?

        raise Errors::ExtensionMissingError.new(klass: self.class)
      end
      # rubocop:enable Lint/MissingSuper

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
      # @param in_file [StorageAdapters::BaseAdapter]
      # @param out_file [StorageAdapters::BaseAdapter]
      # @return [StorageAdapters::BaseAdapter]
      def build_step(in_file:, out_file:, in_tmp_path:)
        image = DerivativeRodeo::Services::ImageService.new(in_tmp_path)
        if image.monochrome?
          # The in_file is already have a monochrome file, no need to run conversions.
          in_file
        else
          # We need to write monochromify and the image.
          monochromify(out_file, image)
        end
      end

      ##
      # Convert the above image to a file at the monochrome_path
      #
      # @param monochrome_file [StorageAdapters::BaseAdapter]
      # @param image [Services::ImageService]
      # @return [StorageAdapters::BaseAdapter]
      def monochromify(monochrome_file, image)
        monochrome_file.with_new_tmp_path do |monochrome_path|
          image.convert(destination: monochrome_path, monochrome: true)
        end
        monochrome_file
      end
    end
  end
end
