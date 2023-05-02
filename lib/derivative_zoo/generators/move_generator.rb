# frozen_string_literal: true

module DerivativeZoo
  ##
  # Responsible for simply moving files from one storage adapter to another
  module Generator
    ##
    # Take images an insure we have a monochrome derivative of them
    class MoveGenerator < BaseGenerator
      ##
      # in_file here should be a monochrome file due to preprocess
      # will run tesseract on the file and store the resulting hocr
      def build_step(in_file:, out_file:)
        @result = nil
        in_file.with_existing_tmp_path do |tmp_path|
          @result = move(tmp_path, out_file)
        end
        @result
      end

      def move(_tmp_path, out_file)
        out_file.with_new_tmp_path do |_out_path|
          out_file.write
        end
        out_file
      end
    end
  end
end
