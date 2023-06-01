# frozen_string_literal: true
require 'marcel'

module DerivativeRodeo
  module Services
    ##
    # This module provides an interface for determining a mime-type.
    module MimeTypeService
      ##
      # Hyrax has it's own compression of mime_types into conceptual types (as defined in
      # Hyrax::FileSetDerivativesService).  This provides a somewhat conceptual overlap with that,
      # while also being more generalized.
      #
      # @param filename [String]
      # @return [Symbol]
      def self.hyrax_type(filename:)
        mime = mime_type(filename: filename)
        media_type, sub_type = mime.split("/")
        case media_type
        when "image", "audio", "text", "video"
          media_type.to_sym
        when "application" # The wild woolly weird world of all the things.
          # TODO: Do we need to worry about office documents?
          sub_type.to_sym
        else
          sub_type.to_sym
        end
      end

      ##
      # Given a local :filename (e.g. downloaded and available on the server this is running),
      # return the mime_type of the file.
      #
      # @param filename [String]
      # @return [String] (e.g. "application/pdf", "text/plain")
      def self.mime_type(filename:)
        ##
        # TODO: Does this attempt to read the whole file?  That may create memory constraints.  By
        # using Pathname (instead of File.read), we're letting Marcel do it's best mime magic.
        pathname = Pathname.new(filename)
        extension = filename.split(".")&.last&.downcase
        if extension
          # By including a possible extension, we can help nudge Marcel into making a more
          # Without extension, we will get a lot of "application/octet-stream" results.
          ::Marcel::MimeType.for(pathname, extension: extension)
        else
          ::Marcel::MimeType.for(pathname)
        end
      end
    end
  end
end
