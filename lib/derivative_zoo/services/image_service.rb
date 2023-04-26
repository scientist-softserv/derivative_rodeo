# frozen_string_literal: true

module DerivativeZoo
  module Service
    ##
    # @api private
    #
    # @see .technical_metadata
    # @see .convert
    class ImageService
      attr_accessor :path

      def initialize(path)
        @path = path
        # The first 23 characters of a file contains the magic.
        @initial_file_contents = File.read(@path, 23, 0)
      end

      def jp2?
        @initial_file_contents.end_with?('ftypjp2')
      end

      # @return [Derivative::Rodeo::TechnicalMetadata]
      def technical_metadata
        return @technical_metadata if defined?(@technical_metadata)

        @technical_metadata = if jp2?
                                ImageJp2Service.technical_metadata_for(path: path)
                              else
                                ImageIdentifyService.technical_metadata_for(path: path)
                              end
      end
      alias metadata technical_metadata

      extend Forwardable
      def_delegator :technical_metadata, :monochrome?

      # Convert source image to image at destination path, inferring file type from destination
      # file extension.  In case of JP2 files, create intermediate file using OpenJPEG 2000 that
      # ImageMagick can use.  Only outputs monochrome output if monochrome is true, destination
      # format is TIFF.
      #
      # @param destination [String] Path to output / destination file
      # @param monochrome [Boolean] true if monochrome output, otherwise false
      def convert(destination:, monochrome: false)
        raise 'JP2 output not yet supported' if destination.end_with?('jp2')

        source = jp2? ? jp2_to_tiff(path) : path
        convert_image(source: source, destination: destination, monochrome: monochrome)
      end

      private

      def convert_image(source:, destination:, monochrome:)
        monochrome &&= destination.slice(-4, 4).index('tif')
        mono_opts = '-depth 1 -monochrome -compress Group4 -type bilevel '
        opts = monochrome ? mono_opts : ''
        cmd = "convert #{source} #{opts}#{destination}"
        `#{cmd}`
      end

      def jp2_to_tiff(source)
        intermediate_path = File.join(Dir.mktmpdir, 'intermediate.tif')
        jp2_cmd = "opj_decompress -i #{source} -o #{intermediate_path}"
        `#{jp2_cmd}`
        intermediate_path
      end
    end
  end
end
