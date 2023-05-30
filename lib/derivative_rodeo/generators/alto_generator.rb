# frozen_string_literal: true

require_relative '../services/extract_word_coordinates_from_hocr_sgml_service'

module DerivativeRodeo
  module Generators
    ##
    # Generate the Alto XML from the given input_uris.
    #
    # @note Assumes that we're receiving a HOCR file (generated via {HocrGenerator}).
    class AltoGenerator < BaseGenerator
      self.output_extension = "alto.xml"

      class_attribute :service, default: Services::ExtractWordCoordinatesFromHocrSgmlService

      ##
      # @param output_location [StorageLocations::BaseLocation]
      # @param input_tmp_file_path [String] the location of the file that we can use for processing.
      #
      # @return [StorageLocations::BaseLocation]
      #
      # @see #requisite_files
      def build_step(output_location:, input_tmp_file_path:, **)
        output_location.with_new_tmp_path do |output_tmp_file_path|
          convert_to_coordinates(path_to_hocr: input_tmp_file_path, path_to_alto: output_tmp_file_path)
        end
      end

      private

      ##
      # @param path_to_hocr [String]
      # @param path_to_alto [String]
      def convert_to_coordinates(path_to_hocr:, path_to_alto:)
        hocr_html = File.read(path_to_hocr)
        File.open(path_to_alto, "w+") do |file|
          file.puts service.call(hocr_html).to_alto
        end
      end
    end
  end
end
