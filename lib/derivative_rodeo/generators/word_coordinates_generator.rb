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
      # @param output_target [StorageTargets::BaseTarget]
      # @param input_tmp_file_path [String] the location of the file that we can use for processing.
      #
      # @return [StorageTargets::BaseTarget]
      #
      # @see #requisite_files
      def build_step(output_target:, input_tmp_file_path:, **)
        output_target.with_new_tmp_path do |output_tmp_file_path|
          convert_to_coordinates(path_to_hocr: input_tmp_file_path, path_to_coordinate: output_tmp_file_path)
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
