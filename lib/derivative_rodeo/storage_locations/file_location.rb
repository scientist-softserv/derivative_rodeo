# frozen_string_literal: true

module DerivativeRodeo
  module StorageLocations
    ##
    # Location for files found on a local disk
    class FileLocation < BaseLocation
      def self.create_uri(path:, parts: :all)
        file_path = file_path_from_parts(path: path, parts: parts)
        "#{adapter_prefix}#{file_path}"
      end

      def self.adapter_prefix
        "#{scheme}://"
      end

      def with_existing_tmp_path(&block)
        with_tmp_path(lambda { |file_path, tmp_file_path, exist|
          raise Errors::FileMissingError.with_info(method: __method__, context: self, file_path: file_path, tmp_file_path: tmp_file_path) unless exist

          FileUtils.cp(file_path, tmp_file_path)
        }, &block)
      end

      def exist?
        File.exist?(file_path)
      end

      # write the file to the file_uri
      def write
        raise Errors::FileMissingError("Use write within a with_new_tmp_path block and fille the mp file with data before writing") unless File.exist?(tmp_file_path)

        FileUtils.mkdir_p(file_dir)
        FileUtils.cp_r(tmp_file_path, file_path)
        file_uri
      end

      ##
      # @return [Enumerable<DerivativeRodeo::StorageLocations::FileLocation>]
      #
      # @see Generators::PdfSplitGenerator#image_file_basename_template
      #
      # @param tail_regexp [Regexp]
      def matching_locations_in_file_dir(tail_regexp:)
        logger.debug("#{self.class}##{__method__} searching for matching files in " \
                    "file_dir: #{file_dir.inspect} " \
                    "with tail_regexp: #{tail_regexp.inspect}.")
        Dir.glob(File.join(file_dir, "*")).each_with_object([]) do |filename, accumulator|
          accumulator << derived_file_from(template: "file://#{filename}") if tail_regexp.match(filename)
        end
      end
    end
  end
end
