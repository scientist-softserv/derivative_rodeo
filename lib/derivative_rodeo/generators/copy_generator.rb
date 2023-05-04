# frozen_string_literal: true

module DerivativeRodeo
  module Generators
    ##
    # Responsible for moving files from one storage adapter to another.
    class CopyGenerator < BaseGenerator
      self.output_extension = StorageAdapters::SAME

      ##
      # Copy files from one adapter to another.
      #
      # @param out_file [StorageAdapters::BaseAdapter]
      # @param in_tmp_path [String]
      # @return [StorageAdapters::BaseAdapter]
      def build_step(out_file:, in_tmp_path:, **)
        copy(in_tmp_path, out_file)
      end

      ##
      # @api private
      def copy(_from_path, out_file)
        out_file.with_new_tmp_path do |_out_path|
          # This space deliberately left blank
        end
        out_file
      end
    end
  end
end
