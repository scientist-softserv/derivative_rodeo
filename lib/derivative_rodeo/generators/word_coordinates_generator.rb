# frozen_string_literal: true

module DerivativeRodeo
  module Generators
    ##
    # Generate the word coordinates (as JSON) from the given input_uris.
    #
    # @note Assumes that we're receiving a HOCR file (generated via {HocrGenerator}).
    class WordCoordinatesGenerator < BaseGenerator
      self.output_extension = "coordinates.json"

      ##
      # @param to_target [StorageAdapters::BaseAdapter]
      # @param from_tmp_path [String] the location of the file that we can use for processing.
      #
      # @return [StorageAdapters::BaseAdapter]
      #
      # @see #requisite_files
      def build_step(to_target:, from_tmp_path:, **)
        to_target.with_new_tmp_path do |to_tmp_path|
          convert_to_coordinates(path_to_hocr: from_tmp_path, path_to_coordinate: to_tmp_path)
        end
      end

      private

      ##
      # @param path_to_hocr [String]
      # @param path_to_coordinate [String]
      # @param service [#call, Services::ExtractWordCoordinatesFromHocrSgmlService]
      def convert_to_coordinates(path_to_hocr:, path_to_coordinate:, service: Services::ExtractWordCoordinatesFromHocrSgmlService)
        hocr_html = File.read(path_to_hocr)
        File.open(path_to_coordinate, "w+") do |file|
          file.puts service.call(hocr_html)
        end
      end
    end
  end
end
