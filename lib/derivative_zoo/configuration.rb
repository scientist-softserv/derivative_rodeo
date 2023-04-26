# frozen_string_literal: true

require 'mime/types'
require 'logger'
module DerivativeZoo
  ##
  # @api public
  #
  # This class is responsible for the consistent configuration of the "application" that leverages
  # the {DerivativeZoo}.
  #
  # This configuration helps set defaults for storage adapters and generators.
  class Configuration
    ##
    # Allows AWS configuration to be set via environment variables by declairing them in the configuration
    # class as follows:
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
      @logger = Logger.new($stderr, level: Logger::FATAL)
      # Note the log level synchronization.
      @dry_run_reporter = ->(string) { logger.info("\n#{string}\n") }
      yield self if block_given?
    end

    attr_accessor :logger

    # TODO: implement dry_run?
    ##
    # @!group Dry Run Configurations
    #
    # The desired mechanism for reporting on the {DryRun} activity.
    #
    # @example
    #   ##
    #   # Send the dry notices to STDERR
    #   Derivative::Rodeo.config do |cfg|
    #     cfg.dry_run_reporter = ->(text) { $stderr.puts text }
    #   end
    # @return [#call]
    attr_accessor :dry_run_reporter

    # @!attribute [rw]
    # @return [Boolean]
    class_attribute :dry_run, default: false
    # @!endgroup Dry Run Configurations

    ##
    # @!group AWS S3 Configuration
    #
    # Various AWS items for S3 Adapter. These can be set from the ENV or the configuration block
    #
    # @example
    # The order we use is:
    # * config.aws_s3_#{variable_name} = value
    # * AWS_S3_#{variable_name}
    # * AWS_#{variable_name}
    # * AWS_DEFAULT_#{variable_name}
    # * default
    #
    # @return [String]

    aws_config prefix: 's3', name: 'region', default: 'us-east-1'
    aws_config prefix: 's3', name: 'bucket'
    aws_config prefix: 's3', name: 'access_key_id'
    aws_config prefix: 's3', name: 'secret_access_key'
    # @!endgroup AWS S3 Configurations
  end
end
