# frozen_string_literal: true

module DerivativeRedeo
  module StorageAdapter
    ##
    # Adapter for files found on a local disk
    #
    class FileAdapter < BaseAdapter
      def self.create_uri(path:, parts: :all)
        file_path = file_path_from_parts(path: path, parts: parts)
        "file://#{file_path}"
      end

      def with_existing_tmp_path(&block)
        with_tmp_path(lambda { |file_path, tmp_file_path, exist|
          raise DerivativeRedeo::FileMissingError unless exist

          FileUtils.cp(file_path, tmp_file_path)
        }, &block)
      end

      def exist?
        File.exist?(file_path)
      end

      # write the file to the file_uri
      def write
        raise DerivativeRedeo::FileMissingError("Use write within a with__new_tmp_path block and fille the mp file with data before writing") unless File.exist?(tmp_file_path)

        FileUtils.mkdir_p(file_dir)
        FileUtils.cp_r(tmp_file_path, file_path)
        file_uri
      end
    end
  end
end
