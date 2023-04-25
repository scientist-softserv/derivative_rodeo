# frozen_string_literal: true

module DerivativeZoo
  module StorageAdapter
    ##
    # Adapter for files found on a local disk
    #
    class FileAdapter < BaseAdapter
      def with_tmp_file
        tmp_file_dir do |dir|
          tmp_file_path = File.join(dir, file_name)
          FileUtils.cp(file_path, tmp_file_path)
          yield tmp_file_path
        end
        self.tmp_file_path = nil
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
