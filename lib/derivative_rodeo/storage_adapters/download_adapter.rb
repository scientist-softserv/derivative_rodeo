# frozen_string_literal: true

require 'faraday'

module DerivativeRedeo
  module StorageAdapter
    ##
    # Adapter for files from the web. Download only, can not write!
    #
    class DownloadAdapter < BaseAdapter
      def self.create_uri(path:, parts: :all, ssl: true)
        file_path = file_path_from_parts(path: path, parts: parts)
        prefix = ssl ? "https://" : "http://"
        "#{prefix}#{file_path}"
      end

      def with_existing_tmp_path(&block)
        with_tmp_path(lambda { |_file_path, tmp_file_path, exist|
                        raise DerivativeRedeo::FileMissingError unless exist

                        response = http_conn.get file_uri
                        File.open(tmp_file_path, 'wb') { |fp| fp.write(response.body) }
                      }, &block)
      end

      def exist?
        connection.head(file_uri).status == 200
      end

      # write the file to the file_uri
      def write
        raise NotImplmentedError
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
