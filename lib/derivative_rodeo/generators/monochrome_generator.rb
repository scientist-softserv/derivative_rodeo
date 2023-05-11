# frozen_string_literal: true

module DerivativeRodeo
  module Generators
    ##
    # Take images an ensures that we have a monochrome derivative of those images.
    class MonochromeGenerator < BaseGenerator
      # TODO: Can we assume a tiff?
      self.output_extension = 'mono.tiff'

      ##
      # @param from_target [StorageAdapters::BaseAdapter]
      # @param out_file [StorageAdapters::BaseAdapter]
      # @return [StorageAdapters::BaseAdapter]
      def build_step(from_target:, out_file:, in_tmp_path:)
        image = DerivativeRodeo::Services::ImageService.new(in_tmp_path)
        if image.monochrome?
          # The from_target is already have a monochrome file, no need to run conversions.
          from_target
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
