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

  ##
  # @param filename [String]
  # @return [String] path to the project's fixture file.
  def self.path_for(filename)
    File.join(FIXTURE_PATH, 'files', filename)
  end

  ##
  # This function copies the given :filenames to a new temporary location.
  #
  # @yieldparam filenames [Array<String>] path to the temporary fixture files.
  def self.with_file_uris_for(*filenames)
    with_temporary_directory do |dir|
      targets = filenames.map do |filename|
        target = File.join(dir, filename)
        FileUtils.cp(path_for(filename), target)
        "file://#{target}"
      end
      yield(targets)
    end
  end
end
