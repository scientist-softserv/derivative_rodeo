# frozen_string_literal: true

module DerivativeRodeo
  module Service
    ##
    # This module is responsible for extracting technical_metadata for a given path.
    #
    # @see .technical_metadata_for
    class ImageIdentifyService < BaseService
      class_attribute :identify_format_option,
                      default: %(Geometry: %G\nDepth: %[bit-depth]\nColorspace: %[colorspace]\nAlpha: %A\nMIME Step: %m\n) # rubocop:disable Layout/LineLength

      ##
      # @api public
      # @param path [String]
      # @return [Derivative::Rodeo::TechnicalMetadata]
      def self.technical_metadata_for(path:)
        new(path).technical_metadata
      end

      def initialize(path)
        super()
        @path = path
        # The first 23 characters of a file contains the magic.
        @initial_file_contents = File.read(@path, 23, 0)
      end
      attr_reader :path

      # Return metadata by means of imagemagick identify
      def technical_metadata
        technical_metadata = TechnicalMetadata.new
        lines = im_identify
        width, height = im_identify_geometry(lines)
        technical_metadata.width = width
        technical_metadata.height = height
        technical_metadata.content_type = im_mime(lines)
        populate_im_color!(lines, technical_metadata)
        technical_metadata
      end

      private

      # @return [Array<String>] lines of output from imagemagick `identify`
      def im_identify
        return @im_identify if defined?(@im_identify)

        # Instead of relying on all of the properties, we're requesting on the specific properties
        cmd = "identify -format '#{identify_format_option}' #{path}"
        # cmd = "identify -verbose #{path}"
        @im_identify = `#{cmd}`.lines
      end

      # @return [Array(Integer, Integer)] width, height in Integer px units
      def im_identify_geometry(lines)
        img_geo = im_line_select(lines, 'geometry').split('+')[0]
        img_geo.split('x').map(&:to_i)
      end

      def im_mime(lines)
        return 'application/pdf' if pdf? # workaround older imagemagick bug

        im_line_select(lines, 'mime step')
      end

      def pdf?
        @initial_file_contents.start_with?('%PDF-')
      end

      def populate_im_color!(lines, technical_metadata)
        bpc = im_line_select(lines, 'depth').split('-')[0].to_i # '1-bit' -> 1
        colorspace = im_line_select(lines, 'colorspace')
        color = colorspace == 'Gray' ? 'gray' : 'color'
        has_alpha = !im_line_select(lines, 'alpha') == 'Undefined'
        technical_metadata.num_components = (color == 'gray' ? 1 : 3) + (has_alpha ? 1 : 0)
        technical_metadata.color = bpc == 1 ? 'monochrome' : color
        technical_metadata.bits_per_component = bpc
      end

      def im_line_select(lines, key)
        line = lines.find { |l| l.scrub.downcase.strip.start_with?(key.downcase) }
        # Given "key: value" line, return the value as String stripped of
        #   leading and trailing whitespace
        return line if line.nil?

        line.strip.split(':')[-1].strip
      end
    end
  end
end
