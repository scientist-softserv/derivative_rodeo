# frozen_string_literal: true

module DerivativeRodeo
  module Generators
    ##
    # This generator is responsible for converting a given binary into a thumbnail.  As of
    # <2023-05-22 Mon>, we're needing to generate thumbnails for PDFs and images.
    class ThumbnailGenerator < BaseGenerator
      ##
      # @!group Class Attributes

      ##
      # We want to mirror the same file "last" extension as described in Hyrax.
      #
      # @see https://github.com/samvera/hyrax/blob/426575a9065a5dd3b30f458f5589a0a705ad7be2/app/services/hyrax/file_set_derivatives_service.rb
      self.output_extension = 'thumbnail.jpeg'

      ##
      # @!attribute dimensions_by_type
      #
      #   @return [Hash<Symbol,String>] the "types" (as categorized by
      #           Hyrax::FileSetDerivativeService).  These aren't mime-types per se but a conceptual
      #           distillation of that.
      #
      #   @see https://github.com/samvera/hyrax/blob/815e0abaacf9f331a5640c5d6129661d01eadf75/app/services/hyrax/file_set_derivatives_service.rb
      class_attribute :dimensions_by_type, default: { pdf: "338x493" }

      ##
      # @!attribute dimensions_fallback
      #
      #   @return [String] when there's no match for {.dimensions_by_type} use this value.
      class_attribute :dimensions_fallback, default: "200x150>"
      # @!endgroup Class Attributes
      ##

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
      # @param filename [String]
      # @return [String]
      #
      # @see .dimensions_by_type
      # @see .dimensions_fallback
      #
      # @note TODO: This is a very quick and dirty and assumptive type detector.  For the 2023-05-31
      #       use case it is likely adequate (e.g. if it ends in .pdf we'll have a configured
      #       match).  In other words, we'd love someone else to be sniffing out mime-types rather
      #       than doing it here.
      def self.dimensions_for(filename:)
        type = filename.split(".")&.last&.to_sym
        dimensions_by_type.fetch(type, dimensions_fallback)
      end

      # Want to expose the dimensions_for as an instance method
      delegate :dimensions_for, to: :class

      ##
      # Convert the file found at :path_to_input into a thumbnail, writing it to the
      # :path_for_thumbnail_output
      #
      # @param path_of_file_to_create_thumbnail_from [String]
      # @param path_for_thumbnail_output [String]
      def thumbnify(path_of_file_to_create_thumbnail_from:, path_for_thumbnail_output:)
        dimensions = dimensions_for(filename: path_of_file_to_create_thumbnail_from)
        `convert #{path_of_file_to_create_thumbnail_from} -thumbnail '#{dimensions}' -flatten #{path_for_thumbnail_output}`
      end
    end
  end
end
