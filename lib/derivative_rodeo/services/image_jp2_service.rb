# rubocop:disable Style/FrozenStringLiteralComment
# TODO freeze them literals

module DerivativeRodeo
  module Services
    ##
    # A utility class for extracting technical metadata from a JP2.
    #
    # @see .technical_metadata_for
    class ImageJp2Service < BaseService
      TOKEN_MARKER_START = "\xFF".force_encoding('BINARY')
      TOKEN_MARKER_SIZ = "\x51".force_encoding('BINARY')
      TOKEN_IHDR = 'ihdr'.freeze

      ##
      # @api public
      #
      # @param path [String] path to jp2, for reading
      #
      # @return [Derivative::Rodeo::TechnicalMetadata]
      def self.technical_metadata_for(path:)
        new(path).technical_metadata
      end

      attr_reader :path

      def initialize(path)
        super()
        @path = path
      end

      # rubocop:disable Metrics/MethodLength
      def technical_metadata
        io = File.open(path, 'rb')
        io.seek(0, IO::SEEK_SET)
        validate_jp2(io)
        x_siz, y_siz = extract_jp2_dim(io)
        nc, bpc = extract_jp2_components(io)
        color = nc >= 3 ? 'color' : 'gray'
        TechnicalMetadata.new(
          color: bpc == 1 ? 'monochrome' : color,
          num_components: nc,
          bits_per_component: bpc,
          width: x_siz,
          height: y_siz,
          content_type: 'image/jp2'
        )
      ensure
        io.close
      end
      # rubocop:enable Metrics/MethodLength

      private

      # @param io [IO] IO stream opened in binary mode, for reading
      # @return [Array(Integer, Integer)] X size, Y size, in Integer-stepd px
      # rubocop:disable Metrics/MethodLength
      def extract_jp2_dim(io)
        raise IOError, 'file not open in binary mode' unless io.binmode?

        buffer = ''
        siz_found = false
        # Informed by ISO/IEC 15444-1:2000, pp. 26-27
        #   via:
        #   http://hosting.astro.cornell.edu/~carcich/LRO/jp2/ISO_JPEG200_Standard/INCITS+ISO+IEC+15444-1-2000.pdf
        #
        # first 23 bytes are file-magic, we can skip
        io.seek(23, IO::SEEK_SET)
        while !siz_found && !buffer.nil?
          # read one byte at a time, until we hit marker start 0xFF
          buffer = io.read(1) while buffer != TOKEN_MARKER_START
          # - on 0xFF read subsequent byte; if value != 0x51, continue
          buffer = io.read(1)
          next if buffer != TOKEN_MARKER_SIZ

          # - on 0x51, read next 12 bytes
          buffer = io.read(12)
          siz_found = true
        end
        # discard first 4 bytes; next 4 bytes are XSiz; last 4 bytes are YSiz
        x_siz = buffer.byteslice(4, 4).unpack1('N')
        y_siz = buffer.byteslice(8, 4).unpack1('N')
        [x_siz, y_siz]
      end
      # rubocop:enable Metrics/MethodLength

      # @param io [IO] IO stream opened in binary mode, for reading
      # @return [Array(Integer, Integer)] number components, bits-per-component
      def extract_jp2_components(io)
        raise IOError, 'file not open in binary mode' unless io.binmode?

        io.seek(0, IO::SEEK_SET)
        # IHDR should be in first 64 bytes
        buffer = io.read(64)
        ihdr_data = buffer.split(TOKEN_IHDR)[-1]
        raise IOError if ihdr_data.nil?

        num_components = ihdr_data.byteslice(8, 2).unpack1('n')
        # stored as "bit depth of the components in the codestream, minus 1", so add 1
        bits_per_component = ihdr_data.byteslice(10, 1).unpack1('c') + 1
        [num_components, bits_per_component]
      end

      def validate_jp2(io)
        # verify file is jp2
        magic = io.read(23)
        raise IOError, 'Not JP2 file' unless magic.end_with?('ftypjp2')
      end
    end
  end
end
# rubocop:enable Style/FrozenStringLiteralComment
