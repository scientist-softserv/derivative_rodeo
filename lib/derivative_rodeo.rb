# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'

require 'byebug' if ENV['DEBUG']

require 'derivative_rodeo/errors'

require 'derivative_rodeo/configuration'
require 'derivative_rodeo/technical_metadata'
require 'derivative_rodeo/version'
# Base Location loads the other adapters
require 'derivative_rodeo/storage_locations/base_location'
require 'derivative_rodeo/generators/base_generator'
require 'derivative_rodeo/services/base_service'

##
# DerivativeRodeo is a gem that allows you to generate derivative files from source files
# It is storage location agnostic, relying on {StorageLocations}. Files can be stored locally or in the cloud.
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
end
