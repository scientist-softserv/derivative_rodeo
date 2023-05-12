# frozen_string_literal: true

require 'faraday'

module DerivativeRodeo
  module StorageTargets
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

      def with_existing_tmp_path(&block)
        with_tmp_path(lambda { |_file_path, tmp_file_path, exist|
                        raise Errors::FileMissingError unless exist

                        response = http_conn.get file_uri
                        File.open(tmp_file_path, 'wb') { |fp| fp.write(response.body) }
                      }, &block)
      end

      ##
      # @return [TrueClass] when the remote file exists
      # @return [FalseClass] when the remote file does not exist
      def exist?
        connection.head(file_uri).status.to_i == 200
      end

      ##
      # Implemented to complete the interface.
      #
      # @raise [NotImplementedError]
      def write
        raise "#{self.class}#write is deliberately not implemented"
      end

      def connection(faraday_adapter: 'default_adapter')
        @connection = Faraday.new do |builder|
          builder.use FaradayMiddleware::FollowRedirects
          builder.adapter Faraday.send(faraday_adapter)
        end
      end
    end
  end
end
