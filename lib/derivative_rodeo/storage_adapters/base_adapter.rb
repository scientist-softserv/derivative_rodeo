# frozen_string_literal: true

require 'tmpdir'

module DerivativeRedeo
  module StorageAdapters
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
        raise DerivativeRedeo::StorageAdapterNotFoundError.new(adapter_name: adapter_name) unless adapters.include?(adapter_name)

        "DerivativeRedeo::StorageAdapters::#{adapter_name.classify}Adapter".constantize
      end

      def self.from_uri(file_uri)
        adapter_name = file_uri.split('://').first
        raise DerivativeRedeo::StorageAdapterMissing.new(file_uri: file_uri) if adapter_name.blank?

        load_adapter(adapter_name).new(file_uri)
      end

      # Registers the adapter with the main StorageAdapter class to it can be used
      def self.register_adapter(adapter_name)
        return if DerivativeRedeo::StorageAdapters::BaseAdapter.adapters.include?(adapter_name)

        DerivativeRedeo::StorageAdapters::BaseAdapter.adapters << adapter_name
      end

      ##
      # Create a new uri of the classes type. Parts argument should have a default in
      # implementing classes. Must support a number or the symbol :all
      #
      # @api public
      #
      # @param path [String]
      # @param parts [Integer, :all]
      # @return [String]
      def self.create_uri(path:, parts:)
        raise NotImplementedError, "#{self.class}.create_uri"
      end

      def self.file_path_from_parts(path:, parts:)
        parts = - parts unless parts == :all || parts.negative?
        parts == :all ? path : path.split('/')[parts..-1].join('/')
      end

      def initialize(file_uri)
        @file_uri = file_uri
      end

      def with_new_tmp_path(&block)
        with_tmp_path(lambda { |_file_path, tmp_file_path, exist|
                        FileUtils.rm_rf(tmp_file_path) if exist
                        FileUtils.touch(tmp_file_path)
                      }, &block)
      end

      def with_existing_tmp_path
        raise NotImplementedError, "#{self.class}#with_existing_tmp_path"
      end

      def with_tmp_path(lambda)
        raise ArgumentError, 'Expected a block' unless block_given?

        tmp_file_dir do |tmpdir|
          self.tmp_file_path = File.join(tmpdir, file_name)
          lambda.call(file_path, tmp_file_path, exist?)
          yield tmp_file_path
        end
        self.tmp_file_path = nil
      end

      # write the tmp file to the file_uri
      def write
        raise NotImplementedError, "#{self.class}#write"
      end

      def exist?
        raise NotImplementedError, "#{self.class}#exist?"
      end
      alias exists? exist?

      def derived_file(extension:, adapter_name: 'same')
        klass = self.class if adapter_name == 'same'
        klass ||= DerivativeRedeo::StorageAdapters::BaseAdapter.load_adapter(adapter_name)
        new_uri = klass.create_uri(path: with_new_extension(extension))
        klass.new(new_uri)
      end

      def with_new_extension(extension)
        "#{file_path.split('.')[0]}.#{extension}"
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

Dir.glob(File.join(__dir__, '**/*')).sort.each do |adapter|
  require adapter unless adapter.match?('base_adapter')
end
