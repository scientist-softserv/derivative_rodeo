# frozen_string_literal: true

module DerivativeRodeo
  module Generators
    ##
    # Take images an ensures that we have a monochrome derivative of those images.
    class MonochromeGenerator < BaseGenerator
      # @see DerivativeRodeo::Services::ConvertUriViaTemplateService for the interaction of the
      #      magic ".mono" suffix
      self.output_extension = 'mono.tiff'

      ##
      # @param input_location [StorageLocations::BaseLocation]
      # @param output_location [StorageLocations::BaseLocation]
      # @return [StorageLocations::BaseLocation]
      def build_step(input_location:, output_location:, input_tmp_file_path:)
        image = DerivativeRodeo::Services::ImageService.new(input_tmp_file_path)
        if image.monochrome?
          # The input_location is already have a monochrome file, no need to run conversions.
          input_location
        else
          # We need to write monochromify and the image.
          monochromify(output_location, image)
        end
      end

      ##
      # Convert the above image to a file at the monochrome_path
      #
      # @param monochrome_file [StorageLocations::BaseLocation]
      # @param image [Services::ImageService]
      # @return [StorageLocations::BaseLocation]
      def monochromify(monochrome_file, image)
        monochrome_file.with_new_tmp_path do |monochrome_path|
          image.convert(destination: monochrome_path, monochrome: true)
        end
      end
    end
  end
end
