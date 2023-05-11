# frozen_string_literal: true
module DerivativeRodeo
  module Generators
    ##
    # A helper module for copying files from one location to another.
    module CopyFileConcern
      ##
      # Copy files from one adapter to another.
      #
      # @param output_target [StorageTargets::BaseTarget]
      # @param input_tmp_file_path [String]
      #
      # @return [StorageTargets::BaseTarget]
      def build_step(output_target:, input_tmp_file_path:, **)
        copy(input_tmp_file_path, output_target)
      end

      ##
      # @api private
      def copy(_from_path, output_target)
        output_target.with_new_tmp_path do |_out_path|
          # This space deliberately left blank; we need to pass a block for all of the magic to
          # happen.
        end
      end
    end
  end
end
