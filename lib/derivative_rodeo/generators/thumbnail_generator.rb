# frozen_string_literal: true

module DerivativeRodeo
  module Generators
    ##
    # This generator is responsible for converting a given binary into a thumbnail.  As of
    # <2023-05-22 Mon>, we're needing to generate thumbnails for PDFs and images.
    class ThumbnailGenerator < BaseGenerator
      ##
      # We want to mirror the same file "last" extension as described in Hyrax.
      #
      # @see https://github.com/samvera/hyrax/blob/426575a9065a5dd3b30f458f5589a0a705ad7be2/app/services/hyrax/file_set_derivatives_service.rb
      self.output_extension = 'thumbnail.jpg'

      ##
      # @param output_location [StorageLocations::BaseLocation]
      # @param input_tmp_file_path [String] the location of the file that we can use for processing.
      #
      # @return [StorageLocations::BaseLocation]
      def build_step(output_location:, input_tmp_file_path:, **)
        output_location.with_new_tmp_path do |out_tmp_path|
          thumbnify(path_of_file_to_create_thumbnail_from: input_tmp_file_path, path_for_thumbnail_output: out_tmp_path)
        end
      end

      ##
      # Convert the file found at :path_to_input into a thumbnail, writing it to the
      # :path_for_thumbnail_output
      #
      # @param path_of_file_to_create_thumbnail_from [String]
      # @param path_for_thumbnail_output [String]
      def thumbnify(path_of_file_to_create_thumbnail_from:, path_for_thumbnail_output:)
        # Put a byebug here is reasonable.
        # Favor and if possible, call the command line tools without any MiniMagick
        # TODO: Do the command-line
        raise NotImplementedError, "Kirk and Deon will be implementing this!"
      end
    end
  end
end
