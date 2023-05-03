# frozen_string_literal: true

module DerivativeRodeo
  module Generators
    ##
    # Take images an ensures that we have a monochrome derivative of those images.
    class MonochromeGenerator < BaseGenerator
      self.output_extension = 'mono.tiff'

      def build_step(in_file:, out_file:)
        @result = nil
        in_file.with_existing_tmp_path do |tmp_path|
          image = DerivativeRodeo::Services::ImageService.new(tmp_path)
          @result = if image.monochrome?
                      in_file
                    else
                      monochromify(out_file, image)
                    end
        end
        @result
      end

      def monochromify(monochrome_file, image)
        # Convert the above image to a file at the monochrome_path
        monochrome_file.with_new_tmp_path do |monochrome_path|
          image.convert(destination: monochrome_path, monochrome: true)
          monochrome_file.write
        end
        monochrome_file
      end
    end
  end
end
