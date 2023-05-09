# frozen_string_literal: true
module DerivativeRodeo
  module Generators
    ##
    # A helper module for copying files from one location to another.
    module CopyFileConcern
      ##
      # Copy files from one adapter to another.
      #
      # @param out_file [StorageAdapters::BaseAdapter]
      # @param in_tmp_path [String]
      #
      # @return [StorageAdapters::BaseAdapter]
      def build_step(out_file:, in_tmp_path:, **)
        copy(in_tmp_path, out_file)
      end

      ##
      # @api private
      def copy(_from_path, out_file)
        out_file.with_new_tmp_path do |_out_path|
          # This space deliberately left blank; we need to pass a block for all of the magic to
          # happen.
        end
        out_file
      end
    end
  end
end
