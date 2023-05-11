# frozen_string_literal: true
module DerivativeRodeo
  module Generators
    ##
    # A helper module for copying files from one location to another.
    module CopyFileConcern
      ##
      # Copy files from one adapter to another.
      #
      # @param to_target [StorageTargets::BaseTarget]
      # @param from_tmp_path [String]
      #
      # @return [StorageTargets::BaseTarget]
      def build_step(to_target:, from_tmp_path:, **)
        copy(from_tmp_path, to_target)
      end

      ##
      # @api private
      def copy(_from_path, to_target)
        to_target.with_new_tmp_path do |_out_path|
          # This space deliberately left blank; we need to pass a block for all of the magic to
          # happen.
        end
      end
    end
  end
end
