# frozen_string_literal: true

module DerivativeRodeo
  module Generators
    ##
    # Responsible for moving files from one storage adapter to another.
    class CopyGenerator < BaseGenerator
      ##
      # @return [TrueClass] Because we don't want to for the requirement of an {.output_extension}.
      def valid_instantiation?
        true
      end

      ##
      # Copy files from one adapter to another.
      #
      # @param in_file [StorageAdapters::BaseAdapter]
      # @param out_file [StorageAdapters::BaseAdapter]
      # @return [StorageAdapters::BaseAdapter]
      def build_step(in_file:, out_file:)
        @result = nil
        in_file.with_existing_tmp_path do |from_path|
          @result = copy(from_path, out_file)
        end
        @result
      end

      ##
      # @param _file [StorageAdapters::BaseAdapter]
      def extension_for(_file)
        raise NotImplementedError
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
