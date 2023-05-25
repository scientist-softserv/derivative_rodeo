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

      delegate :config, to: DerivativeRodeo

      def with_existing_tmp_path(&block)
        with_tmp_path(lambda { |_file_path, tmp_file_path, exist|
          raise Errors::FileMissingError unless exist

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
      def read(url)
        HTTParty.get(url, logger: config.logger)
      rescue => e
        config.logger.error(%(#{e.message}\n#{e.backtrace.join("\n")}))
        raise e
      end

      ##
      # @param url [String]
      #
      # @return [URI] when the URL resolves successfully
      # @return [FalseClass] when the URL's head request is not successful or we've exhausted our
      #         remaining redirects.
      def exists?(url)
        HTTParty.head(url, logger: config.logger)
      rescue => e
        config.logger.error(%(#{e.message}\n#{e.backtrace.join("\n")}))
        false
      end
    end
  end
end
