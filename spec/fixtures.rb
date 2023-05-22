# frozen_string_literal: true
module Fixtures
  ##
  # Will create and clean-up a temporary directory
  #
  # @yieldparam [String]
  def self.with_temporary_directory
    raise "You must pass a block" unless block_given?

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
  # @yieldparam output_tmp_dir [String] (Optional) path to the temporary directory where we copied
  #             the files.
  def self.with_file_uris_for(*filenames, &block)
    raise "You must pass a block" unless block_given?

    with_temporary_directory do |dir|
      locations = filenames.map do |filename|
        location = File.join(dir, filename)
        FileUtils.cp(path_for(filename), location)
        "file://#{location}"
      end
      yield(locations) if block.arity == 1
      yield(locations, dir) if block.arity == 2
    end
  end
end
