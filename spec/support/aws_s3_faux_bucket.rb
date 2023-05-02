# frozen_string_literal: true
##
# This class is very rudimentary implementation of a bucket.  It conforms to the necessary
# interface for downloading and uploading.
#
# @see [Derivative::Rodeo::StorageAdapters::AwsS3Adapter]
class AwsS3FauxBucket
  def initialize
    @storage = {}
  end
  attr_reader :storage
  def object(path)
    # Yup, we've got nested buckets
    @storage[path] ||= Storage.new
  end

  def objects(prefix:)
    @storage.select do |path, _file|
      path.start_with?(prefix)
    end
  end

  class Storage
    def initialize
      @storage = {}
    end
    attr_reader :storage

    def upload_file(path)
      @storage[:upload] = path
    end

    def download_file(path)
      return false unless @storage.key?(:upload)
      storage_path = @storage.fetch(:upload)
      File.open(path, 'wb') do |f|
        if File.file?(storage_path)
          f.puts File.read(storage_path)
        else
          f.puts DerivativeRedeo::Servce::UrlService.read(storage_path)
        end
      end
    end
  end
end
