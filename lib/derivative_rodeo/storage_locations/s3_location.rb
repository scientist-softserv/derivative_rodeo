# frozen_string_literal: true

require 'aws-sdk-s3'

module DerivativeRodeo
  module StorageLocations
    ##
    # Location to download and upload files to S3
    #
    class S3Location < BaseLocation
      ##
      # @!group Class Attributes
      # @!attribute use_actual_s3_bucket
      #
      # When true , we are going to use a live S3 bucket.  When false, we'll use a fake local bucket.
      class_attribute :use_actual_s3_bucket, default: true
      # @!endgroup Class Attributes
      ##

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
        File.join("#{adapter_prefix}/#{file_path}")
      end

      ##
      # @param config [DerivativeRodeo::Configuration]
      # @return [String]
      def self.adapter_prefix(config: DerivativeRodeo.config)
        "#{scheme}://#{config.aws_s3_bucket}.s3.#{config.aws_s3_region}.amazonaws.com"
      end

      ##
      # @api public
      # download or copy the file to a tmp path
      # deletes the tmp file after the block is executed
      #
      # @return [String] the path to the tmp file
      def with_existing_tmp_path(&block)
        with_tmp_path(lambda { |file_path, tmp_file_path, exist|
                        raise Errors::FileMissingError unless exist
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
        raise Errors::FileMissingError("Use write within a with__new_tmp_path block and fill the tmp file with data before writing") unless File.exist?(tmp_file_path)

        obj = bucket.object(file_path)
        obj.upload_file(tmp_file_path)
        file_uri
      end

      ##
      # @api private
      #
      # @return [Aws::S3::Resource]
      def resource
        # TODO: Are there instantiation considerations when running in Lambda?  In tests
        # initializing a resource is very slow (e.g. 3 seconds or so).  Should this be a class
        # method?  Can it be given the SpaceStone constraints?
        @resource ||= if DerivativeRodeo.config.aws_s3_access_key_id
                        Aws::S3::Resource.new(region: DerivativeRodeo.config.aws_s3_region,
                                              credentials: Aws::Credentials.new(
                                                DerivativeRodeo.config.aws_s3_access_key_id,
                                                DerivativeRodeo.config.aws_s3_secret_access_key
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
        raise Errors::BucketMissingError
      end

      # @see .use_actual_s3_bucket
      def bucket
        @bucket ||= if use_actual_s3_bucket?
                      resource.bucket(bucket_name)
                    else
                      faux_bucket
                    end
      end

      def file_path
        @file_path ||= @file_uri.sub(%r{.+://.+?/}, '')
      end

      ##
      # A fake constructed fake bucket that confroms to the narrow S3 interface that we use.
      #
      # @see .use_actual_s3_bucket
      # @return [AwsS3FauxBucket]
      def faux_bucket
        # We are not requiring this file; except in the spec context.
        AwsS3FauxBucket.new
      end
    end
  end
end
