# frozen_string_literal: true
module DerivativeRodeo
  module Generators
    ##
    # A helper module for copying files from one location to another.
    module CopyFileConcern
      ##
      # Copy files from one adapter to another.
      #
      # @param output_location [StorageLocations::BaseLocation]
      # @param input_tmp_file_path [String]
      #
      # @return [StorageLocations::BaseLocation]
      def build_step(output_location:, input_tmp_file_path:, **)
        copy(input_tmp_file_path, output_location)
      end

      ##
      # @api private
      def copy(from_path, output_location)
        output_location.with_new_tmp_path do |out_path|
          # We can move here because we are done with the tmp file after this.
          FileUtils.mv(from_path, out_path)
        end
      end
    end
  end
end
