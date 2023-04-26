# frozen_string_literal: true

require 'httparty'

module Derivative
  module Rodeo
    module Utilities
      ##
      # A utility class for handling general URLs.  Provided as a means of easing the implementation
      # logic of those that use this class.
      #
      # @note
      #   It is a good design idea to wrap a library (in this case HTTParty).  The goal is to expose
      #   the smallest interface and make it something that would be easy to swap out.
      #
      # @see https://rubygems.org/gems/httparty
      module Url
        ##
        # @param url [String]
        # @param config [Derivative::Rodeo::Configuration]
        #
        # @return [String]
        def self.read(url, config: Rodeo.config)
          HTTParty.get(url, logger: config.logger).body
        rescue StandardError => e
          config.logger.error(%(#{e.message}\n#{e.backtrace.join("\n")}))
          raise e
        end

        ##
        # @param url [String]
        # @param config [Derivative::Rodeo::Configuration]
        #
        # @return [URI] when the URL resolves successfully
        # @return [FalseClass] when the URL's head request is not successful or we've exhausted our
        #         remaining redirects.
        def self.exists?(url, config: Rodeo.config)
          HTTParty.head(url, logger: config.logger)
        rescue StandardError => e
          config.logger.error(%(#{e.message}\n#{e.backtrace.join("\n")}))
          false
        end
      end
    end
  end
end
