# frozen_string_literal: true

module DerivativeRedeo
  module Service
    module PdfSplitter
      ##
      # The purpose of this class is to split the PDF into constituent tiff files.
      class TiffPage < PdfSplitter::Base
        self.image_extension = 'tiff'
        self.compression = 'lzw'

        ##
        # @api private
        #
        # @return [String]
        def gsdevice
          return @gsdevice if defined?(@gsdevice)

          color = pdf_pages_summary.color_description
          channels = pdf_pages_summary.channels
          bpc = pdf_pages_summary.bits_per_channel

          @gsdevice = color_bpc(color, bpc)

          # otherwise color:
          @gsdevice ||= colordevice(channels, bpc)
        end

        def color_bpc(color, bpc)
          return unless color == 'gray'

          # CCITT Group 4 Black and White, if applicable:
          if bpc == 1
            self.compression = 'g4'
            'tiffg4'
          elsif bpc > 1
            # 8 Bit Grayscale, if applicable:
            'tiffgray'
          end
        end

        def colordevice(channels, bpc)
          bits = bpc * channels
          # will be either 8bpc/16bpd color TIFF,
          #   with any CMYK source transformed to 8bpc RBG
          bits = 24 unless [24, 48].include? bits
          "tiff#{bits}nc"
        end
      end
    end
  end
end
