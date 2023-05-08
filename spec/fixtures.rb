# frozen_string_literal: true
module Fixtures
  ##
  # Will create and clean-up a temporary directory
  #
  # @yieldparam [String]
  def self.with_temporary_directory
    Dir.mktmpdir do |dir|
      yield(dir)
    end
  end
end
