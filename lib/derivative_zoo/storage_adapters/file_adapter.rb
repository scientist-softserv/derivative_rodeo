# frozen_string_literal: true

module DerivativeZoo
  module StorageAdapter
    ##
    # Adapter for files found on a local disk
    #
    class FileAdapter < BaseAdapter
      def self.create_uri(file_path)
        "file://#{file_path}"
      end

      def with_existing_tmp_path(&block)
        with_tmp_path(lambda { |file_path, tmp_file_path, exists|
          raise DerivativeZoo::FileMissingError unless exists

          FileUtils.cp(file_path, tmp_file_path)
        }, &block)
      end

      def with_new_tmp_path(&block)
        with_tmp_path(lambda { |_file_path, tmp_file_path, exists|
                        FileUtils.rm_rf(tmp_file_path) if exists
                        FileUtils.touch(tmp_file_path)
                      }, &block)
      end

      def with_tmp_path(lambda)
        raise ArgumentError, 'Expected a block' unless block_given?

        tmp_file_dir do |tmpdir|
          self.tmp_file_path = File.join(tmpdir, file_name)
          lambda.call(file_path, tmp_file_path, exists?)
          yield tmp_file_path
        end
        self.tmp_file_path = nil
      end

      def exists?
        File.exist?(file_path)
      end

      # write the file to the file_uri
      def write
        raise DerivativeZoo::FileMissingError unless File.exist?(tmp_file_path)

        FileUtils.mkdir_p(file_dir)
        FileUtils.mv(tmp_file_path, file_path)
        file_uri
      end
    end
  end
end
