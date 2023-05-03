# frozen_string_literal: true

module DerivativeRodeo
  module Service
    module PdfSplitter
      # The purpose of this class is to split the PDF into constituent png files.
      class PngPage < PdfSplitter::Base
        self.image_extension = 'png'

        def gsdevice
          return @gsdevice if defined?(@gsdevice)

          color = pdf_pages_summary.color_description
          bits_per_channel = pdf_pages_summary.bits_per_channel
          if color == 'gray'
            # 1 Bit Grayscale, if applicable:
            return @gsdevice = 'pngmonod' if bits_per_channel == 1
            return @gsdevice = 'pnggray' if bits_per_channel > 1
          end

          @gsdevice = 'png16m'
        end
      end
    end
  end
end
