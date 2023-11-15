# frozen_string_literal: true

require 'httparty'

module DerivativeRodeo
  module StorageLocations
    ##
    # A helper module for copying files from one location to another.
    module DownloadConcern
      extend ActiveSupport::Concern

      class_methods do
        def create_uri(path:, parts: :all, ssl: true)
          file_path = file_path_from_parts(path: path, parts: parts)
          "#{adapter_prefix(ssl: ssl)}#{file_path}"
        end

        def adapter_prefix(ssl: true)
          ssl ? "https://" : "http://"
        end
      end

      delegate :logger, to: DerivativeRodeo

      def with_existing_tmp_path(&block)
        with_tmp_path(lambda { |file_path, tmp_file_path, exist|
          raise Errors::FileMissingError.with_info(method: __method__, context: self, file_path: file_path, tmp_file_path: tmp_file_path) unless exist

          response = get(file_uri)
          File.open(tmp_file_path, 'wb') { |fp| fp.write(response.body) }
        }, &block)
      end

      ##
      # Implemented to complete the interface.
      #
      # @raise [NotImplementedError]
      def write
        raise "#{self.class}#write is deliberately not implemented"
      end

      ##
      # @param url [String]
      #
      # @return [String]
      def get(url)
        HTTParty.get(url, logger: logger)
      rescue => e
        logger.error(%(#{e.message}\n#{e.backtrace.join("\n")}))
        raise e
      end

      ##
      # @return [URI] when the URL resolves successfully
      # @return [FalseClass] when the URL's head request is not successful or we've exhausted our
      #         remaining redirects.
      def exist?
        HTTParty.head(file_uri, logger: logger)
      rescue => e
        logger.error(%(#{e.message}\n#{e.backtrace.join("\n")}))
        false
      end

      ##
      # @param tail_regexp [Regex] the file pattern that we're looking to find; but due to the
      #        nature of this location adapter, it won't matter.
      # @return [Array] always returns an empty array.
      #
      # @see S3Location#matching_locations_in_file_dir
      # @see FileLocation#matching_locations_in_file_dir
      def matching_locations_in_file_dir(tail_regexp:)
        logger.info("#{self.class}##{__method__} for file_uri: #{file_uri.inspect}, tail_regexp: #{tail_regexp} will always return an empty array.  This is the nature of the #{self.class} location.")

        []
      end
    end
  end
end
