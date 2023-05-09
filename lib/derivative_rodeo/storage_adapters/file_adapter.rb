# frozen_string_literal: true

module DerivativeRodeo
  module StorageAdapters
    ##
    # Adapter for files found on a local disk
    class FileAdapter < BaseAdapter
      def self.create_uri(path:, parts: :all)
        file_path = file_path_from_parts(path: path, parts: parts)
        "#{scheme}://#{file_path}"
      end

      ##
      # Build a {StorageAdapters::BaseAdapter} by converting the :from_uri with the :template via
      # the given :service.
      #
      # @param from_uri [String]
      # @param template [String]
      # @param service [#call, Module<DerivativeRodeo::Services::ConvertUriViaTemplateService>]
      #
      # @return [StorageAdapters::BaseAdapter]
      def self.build(from_uri:, template:, service: DerivativeRodeo::Services::ConvertUriViaTemplateService)
        # HACK: Ensuring that we have the correct scheme.  Maybe this is a hack?
        from_uri = "#{scheme}://#{from_uri}" unless from_uri.start_with?("#{scheme}://")
        to_uri = service.call(from_uri: from_uri, template: template, adapter: self)
        new(to_uri)
      end

      def with_existing_tmp_path(&block)
        with_tmp_path(lambda { |file_path, tmp_file_path, exist|
          raise Errors::FileMissingError unless exist

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
    end
  end
end
