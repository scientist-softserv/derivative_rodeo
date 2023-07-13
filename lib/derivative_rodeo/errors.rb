# frozen_string_literal: true
module DerivativeRodeo
  ##
  # A module namespace for establishing the possible errors that the {DerivativeRodeo} could raise.
  # The rodeo could raise other errors, but these are the ones we've named.
  module Errors
    ##
    # That which all DerivativeRodeo errors shall extend!
    class Error < StandardError; end

    ##
    # Raised when a file uri is passed in that does not contain a storage adapter part before the ://
    class StorageLocationMissing < Error
      def initialize(file_uri: '')
        super("#{file_uri} does not contain an adapter. Should look like file:///my_dir/myfile or s3://bucket_name/location/file_name. The part before the :// is used to select the storage adapter.") # rubocop:disable Layout/LineLength
      end
    end

    ##
    # Raised when a storage adapter is called for but does not exist in the registered adapter list
    class StorageLocationNotFoundError < Error
      def initialize(location_name: '')
        super("Could not find the adapter #{location_name}. Make sure it is required and registerd properly.")
      end
    end

    ##
    # Raised when a storage adapter is called for but does not exist in the registered adapter list
    class MaxQueueSize < Error
      def initialize(batch_size:)
        super("Batch size #{batch_size} is larger than the max queue size #{DerivativeRodeo.config.aws_sqs_max_batch_size}")
      end
    end

    ##
    # Raised when AWS bucket does not exist or is not accessible by current permissions
    class BucketMissingError < Error
      def initialize(file_uri:)
        super("Bucket part missing #{file_uri}")
      end
    end

    ##
    # Raised when trying to write a tmp file that does not exist
    class FileMissingError < Error
    end

    ##
    # Raised because the Generator class must declare an extension for the output file extension
    class ExtensionMissingError < Error
      def initialize(klass: '')
        super("Extension must be declared in the Generator class #{klass}")
      end
    end
  end
end
