# frozen_string_literal: true

##
# This class is very rudimentary implementation of a bucket.  It conforms to the necessary
# interface for downloading and uploading and filter on prefix.
#
# It is provided as a lib/spec/support so that downstream implementations can leverage a fake S3
# bucket.
#
# @see [DerivativeRodeo::StorageLocations::S3Location]
class AwsS3FauxBucket
  def initialize
    @storage = {}
  end
  attr_reader :storage
  def object(path)
    # Yup, we've got nested buckets
    @storage[path] ||= Storage.new(key: path)
  end

  def objects(prefix:)
    @storage.each_with_object([]) do |(path, obj), accumulator|
      accumulator << obj if path.start_with?(prefix)
    end
  end

  class Storage
    # Because we're now coping with the glob tail finder, we need to account for the bucket entry's
    # key.
    def initialize(key:)
      @key = key
      @storage = {}
    end
    attr_reader :storage, :key

    def upload_file(path)
      @storage[:upload] = File.read(path)
    end

    def download_file(path)
      return false unless @storage.key?(:upload)
      content = @storage.fetch(:upload)
      File.open(path, 'wb') do |f|
        f.puts(content)
      end
    end
  end
end
