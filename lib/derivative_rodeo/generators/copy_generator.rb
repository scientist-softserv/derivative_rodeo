# frozen_string_literal: true

module DerivativeRodeo
  module Generators
    ##
    # Responsible for moving files from one storage adapter to another.
    class CopyGenerator < BaseGenerator
      ##
      # will copy files from one adapter to another
      def build_step(in_file:, out_file:)
        @result = nil
        in_file.with_existing_tmp_path do |tmp_path|
          @result = copy(tmp_path, out_file)
        end
        @result
      end

      ##
      # @api private
      def copy(_tmp_path, out_file)
        out_file.with_new_tmp_path do |_out_path|
          out_file.write
        end
        out_file
      end
    end
  end
end
