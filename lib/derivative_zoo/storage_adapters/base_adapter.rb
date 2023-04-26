# frozen_string_literal: true

module DerivativeZoo
  module StorageAdapter
    # dir is the directory path
    # path is the full file path
    # uri is the full file path plus the uri prefix parts
    class BaseAdapter
      attr_accessor :file_uri, :tmp_file_path

      @adapters = []

      def self.adapters
        @adapters ||= []
      end

      def self.inherited(subclass)
        adapters << subclass.to_s.demodulize.underscore.sub(/_adapter$/, '')
        super
      end

      def self.load_adapter(adapter_name)
        raise DerivativeZoo::StorageAdapterNotFound.new(adapter_name: adapter_name) unless adapters.include?(adapter_name)

        "DerivativeZoo::StorageAdapter::#{adapter_name.classify}Adapter".constantize
      end

      def self.from_uri(file_uri)
        adapter_name = file_uri.split('://').first
        raise DerivativeZoo::StorageAdapterMissing.new(file_uri: file_uri) if adapter_name.blank?

        load_adapter(adapter_name)
      end

      # Registers the adapter with the main StorageAdapter class to it can be used
      def self.register_adapter(adapter_name)
        return if DerivativeZoo::StorageAdapter::BaseAdapter.adapters.include?(adapter_name)

        DerivativeZoo::StorageAdapter::BaseAdapter.adapters << adapter_name
      end

      def self.create_uri(file_path)
        raise NotImplementedError
      end

      def initialize(file_uri)
        @file_uri = file_uri
      end

      def with_new_tmp_path
        raise NotImplementedError
      end

      def with_existing_tmp_path
        raise NotImplementedError
      end

      # write the tmp file to the file_uri
      def write
        raise NotImplementedError
      end

      def exists?
        raise NotImplementedError
      end

      def derived_file(extension:, adapter_name: 'same')
        klass = self.class if adapter_name == 'same'
        klass ||= DerivativeZoo::StorageAdapter::BaseAdapter.load_adapter(adapter_name)
        new_uri = klass.create_uri(with_new_extension(extension))
        klass.new(new_uri)
      end

      def with_new_extension(extension)
        "#{file_path.split('.')[0..-2].join('.')}.#{extension}"
      end

      def file_path
        @file_path ||= @file_uri.sub(%r{.+://}, '')
      end

      def file_dir
        @file_dir ||= File.dirname(file_path)
      end

      def file_name
        @file_name ||= File.basename(file_path)
      end

      def tmp_file_dir(&block)
        raise ArgumentError, 'Expected a block' unless block_given?

        Dir.mktmpdir(&block)
      end
    end
  end
end

Dir.glob(File.join(__dir__, '**')).sort.each do |adapter|
  require adapter unless adapter.match?('base_adapter')
end
