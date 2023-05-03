# frozen_string_literal: true

require 'mime/types'
require 'logger'
module DerivativeRedeo
  ##
  # @api public
  #
  # This class is responsible for the consistent configuration of the "application" that leverages
  # the {DerivativeRedeo}.
  #
  # This configuration helps set defaults for storage adapters and generators.
  class Configuration
    ##
    # Allows AWS configuration to be set via environment variables by declairing them in the configuration
    # class as follows:
    #
    # @example
    #
    #  aws_config prefix: 's3', name: 'region', default: 'us-east-1'
    #
    # @param prefix [String]
    # @param name [String]
    # @param default [String] (optional)
    #
    # @return [getter and setter for the variable]
    def self.aws_config(prefix:, name:, default: nil)
      aws_config_getter(prefix: prefix, name: name, default: default)
      aws_config_setter(prefix: prefix, name: name)
    end

    def self.aws_config_getter(prefix:, name:, default: nil)
      define_method "aws_#{prefix}_#{name}" do
        val = instance_variable_get("@aws_#{prefix}_#{name}")
        return val if val

        val = ENV["AWS_#{prefix.upcase}_#{name.upcase}"] ||
              ENV["AWS__#{name.upcase}"] ||
              ENV["AWS_DEFAULT_#{name.upcase}"] ||
              default
        instance_variable_set("@aws_#{prefix}_#{name}", val)
      end
    end

    def self.aws_config_setter(prefix:, name:)
      define_method "aws_#{prefix}_#{name}=" do |val|
        instance_variable_set("@aws_#{prefix}_#{name}", val)
      end
    end

    def initialize
      # By default, minimize the chatter of the specs; we may want to consider piggybacking on
      # whether Rails is defined or not.
      @logger = Logger.new($stderr, level: Logger::FATAL)
      yield self if block_given?
    end

    ##
    # @return [Logger]
    attr_accessor :logger

    ##
    # @!group AWS S3 Configuration
    #
    # Various AWS items for {StorageAdapters::S3Adapter}. These can be set from the ENV or the configuration block
    #
    # @note
    #
    #   The order we use is:
    #   * `config.aws_s3_<variable_name> = value`
    #   * `AWS_S3_<variable_name>`
    #   * `AWS_<variable_name>`
    #   * `AWS_DEFAULT_<variable_name>`
    #   * default
    #
    # @return [String]

    aws_config prefix: 's3', name: 'region', default: 'us-east-1'
    aws_config prefix: 's3', name: 'bucket'
    aws_config prefix: 's3', name: 'access_key_id'
    aws_config prefix: 's3', name: 'secret_access_key'

    aws_config prefix: 'sqs', name: 'region', default: 'us-east-1'
    aws_config prefix: 'sqs', name: 'queue'
    aws_config prefix: 'sqs', name: 'access_key_id'
    aws_config prefix: 'sqs', name: 'secret_access_key'
    aws_config prefix: 'sqs', name: 'max_batch_size', default: 10
    # @!endgroup AWS SQS Configurations
  end
end
