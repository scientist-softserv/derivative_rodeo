# frozen_string_literal: true

require 'aws-sdk-s3'

module DerivativeZoo
  module StorageAdapter
    ##
    # Adapter to download and upload files to S3
    #
    class S3Adapter < BaseAdapter
      ##
      # @api public
      # download or copy the file to a tmp path
      # deletes the tmp file after the block is executed
      #
      # @return [String] the path to the tmp file
      def with_tmp_path
        tmp_file_dir do |dir|
          tmp_file_path = File.join(dir, file_name)
          obj = bucket.object(file_path)
          obj.download_file(tmp_file_path)
          yield tmp_file_path
        end
        self.tmp_file_path = nil
      end

      ##
      # @api public
      # write the tmp file to the file_uri
      #
      # @return [String] the file_uri
      def write
        raise DerivativeZoo::FileMissingError unless File.exist?(tmp_file_path)

        obj = bucket.object(file_path)
        obj.upload_file(tmp_file_path)
        file_uri
      end

      ##
      # @api private
      #
      # @reutnr [Aws::S3::Resource]
      def resource
        @resource ||= if DerivativeZoo.aws_s3_access_key_id
                        Aws::S3::Resource.new(region: DerivativeZoo.aws_s3_region,
                                              credentials: Aws::Credentials.new(
                                                DerivativeZoo.aws_s3_access_key_id,
                                                DerivativeZoo.aws_s3_secret_access_key
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
        raise DerivativeZoo::BucketMissingError
      end

      def bucket
        @bucket ||= resource.bucket(bucket_name)
      end
    end
  end
end
