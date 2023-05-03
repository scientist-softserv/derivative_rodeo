# frozen_string_literal: true

require 'aws-sdk-s3'

module DerivativeRedeo
  module StorageAdapters
    ##
    # Adapter to download and upload files to S3
    #
    class S3Adapter < BaseAdapter
      attr_writer :bucket
      ##
      # Create a new uri of the classes type. Parts argument should have a default in
      # implementing classes. Must support a number or the symbol :all
      #
      # @api public
      #
      # @param path [String]
      # @param parts [Integer, :all], defaults to 2 for S3 which is parent_dir/file_name.ext
      # @return [String]
      def self.create_uri(path:, parts: 2)
        file_path = file_path_from_parts(path: path, parts: parts)
        "s3://#{DerivativeRedeo.config.aws_s3_bucket}.s3.#{DerivativeRedeo.config.aws_s3_region}.amazonaws.com/#{file_path}"
      end

      ##
      # @api public
      # download or copy the file to a tmp path
      # deletes the tmp file after the block is executed
      #
      # @return [String] the path to the tmp file
      def with_existing_tmp_path(&block)
        with_tmp_path(lambda { |file_path, tmp_file_path, exist|
                        raise DerivativeRedeo::FileMissingError unless exist
                        obj = bucket.object(file_path)
                        obj.download_file(tmp_file_path)
                      }, &block)
      end

      ##
      # @api public
      #
      # Existance is futile
      # @return [Boolean]
      def exist?
        bucket.objects(prefix: file_path).count.positive?
      end

      ##
      # @api public
      # write the tmp file to the file_uri
      #
      # @return [String] the file_uri
      def write
        raise DerivativeRedeo::FileMissingError("Use write within a with__new_tmp_path block and fille the mp file with data before writing") unless File.exist?(tmp_file_path)

        obj = bucket.object(file_path)
        obj.upload_file(tmp_file_path)
        file_uri
      end

      ##
      # @api private
      #
      # @return [Aws::S3::Resource]
      def resource
        @resource ||= if DerivativeRedeo.config.aws_s3_access_key_id
                        Aws::S3::Resource.new(region: DerivativeRedeo.config.aws_s3_region,
                                              credentials: Aws::Credentials.new(
                                                DerivativeRedeo.config.aws_s3_access_key_id,
                                                DerivativeRedeo.config.aws_s3_secret_access_key
                                              ))
                      else
                        Aws::S3::Resource.new
                      end
      end

      ##
      # @api private
      # https://long-term-video-storage.s3.eu-west-1.amazonaws.com/path1/path2/file.tld
      def bucket_name
        @bucket_name ||= file_uri.match(%r{s3://(.+)\.s3})&.[](1)
      rescue StandardError
        raise DerivativeRedeo::BucketMissingError
      end

      def bucket
        @bucket ||= resource.bucket(bucket_name)
      end

      def file_path
        @file_path ||= @file_uri.sub(%r{.+://.+?/}, '')
      end
    end
  end
end
