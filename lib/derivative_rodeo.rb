# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'

require 'byebug' if ENV['DEBUG']

require 'derivative_rodeo/configuration'
require 'derivative_rodeo/technical_metadata'
require 'derivative_rodeo/version'
# Base Adapter loads the other adapters
require 'derivative_rodeo/storage_adapters/base_adapter'
require 'derivative_rodeo/generators/base_generator'
require 'derivative_rodeo/services/base_service'

##
# DerivativeRodeo is a gem that allows you to generate derivative files from source files
# It is storage location agnostic, relying on {StorageAdapters}. Files can be stored locally or in the cloud.
# {Generators} are designed to be simple to create and to short circut logic if a
# pre processed version exists
module DerivativeRodeo
  ##
  # The {Configuration} that the various processes in your implementation will use.
  #
  # @api public
  #
  # @yieldparam [Derivative::Rodeo::Configuration]
  # @return [Derivative::Rodeo::Configuration]
  def self.config
    @config ||= Configuration.new
    yield(@config) if block_given?
    @config
  end

  class Error < StandardError; end

  ##
  # Raised when a file uri is passed in that does not contain a storage adapter part before the ://
  class StorageAdapterMissing < Error
    def initialize(file_uri: '')
      super("#{file_uri} does not contain an adapter. Should look like file:///my_dir/myfile or s3://bucket_name/location/file_name. The part before the :// is used to select the storage adapter.") # rubocop:disable Layout/LineLength
    end
  end

  ##
  # Raised when a storage adapter is called for but does not exist in the registered adapter list
  class StorageAdapterNotFoundError < Error
    def initialize(adapter_name: '')
      super("Could not find the adapter #{adapter_name}. Make sure it is required and registerd properly.")
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
    def initialize
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
