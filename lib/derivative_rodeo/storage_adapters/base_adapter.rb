# frozen_string_literal: true

require 'tmpdir'

module DerivativeRodeo
  module StorageAdapters
    ##
    # When the output adapter is the same type of adapter as "this" adapter, we indicate that via
    # the SAME constant.
    SAME = :same

    ##
    # The base adapter for storing files.
    #
    # - dir :: is the directory path
    # - path :: is the full file path
    # - uri :: is the full file path plus the uri prefix parts
    class BaseAdapter
      attr_accessor :file_uri, :tmp_file_path

      @adapters = []

      ##
      # @return [Array<String>]
      def self.adapters
        @adapters ||= []
      end

      def self.inherited(subclass)
        adapters << subclass.adapter_name
        super
      end

      ##
      # @return [String]
      def self.adapter_name
        to_s.demodulize.underscore.sub(/_adapter$/, '')
      end

      ##
      # @param adapter_name [String]
      #
      # @return [Class]
      def self.load_adapter(adapter_name)
        adapter_name = adapter_name.split("://").first
        raise Errors::StorageAdapterNotFoundError.new(adapter_name: adapter_name) unless adapters.include?(adapter_name)

        "DerivativeRodeo::StorageAdapters::#{adapter_name.to_s.classify}Adapter".constantize
      end

      ##
      # @param file_uri [String] of the form scheme://arbitrary-stuff
      #
      # @return [BaseAdapter]
      def self.from_uri(file_uri)
        adapter_name = file_uri.split('://').first
        raise Errors::StorageAdapterMissing.new(file_uri: file_uri) if adapter_name.blank?

        load_adapter(adapter_name).new(file_uri)
      end

      ##
      # Registers the adapter with the main StorageAdapter class to it can be used
      #
      # @param adapter_name [String]
      def self.register_adapter(adapter_name)
        return if DerivativeRodeo::StorageAdapters::BaseAdapter.adapters.include?(adapter_name.to_s)

        DerivativeRodeo::StorageAdapters::BaseAdapter.adapters << adapter_name.to_s
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
      #
      # @see .file_path_from_parts
      def self.create_uri(path:, parts:)
        raise NotImplementedError, "#{self.class}.create_uri"
      end

      ##
      # @param path [String]
      # @param parts [Integer, :all]
      #
      # @return [String]
      def self.file_path_from_parts(path:, parts:)
        parts = - parts unless parts == :all || parts.negative?
        parts == :all ? path : path.split('/')[parts..-1].join('/')
      end

      def initialize(file_uri)
        @file_uri = file_uri
      end

      ##
      # @param auto_write_file [Boolean] Provided as a testing helper method.
      #
      # @yieldparam tmp_file_path [String]
      # @see with_tmp_path
      def with_new_tmp_path(auto_write_file: true, &block)
        with_tmp_path(lambda { |_file_path, tmp_file_path, exist|
                        FileUtils.rm_rf(tmp_file_path) if exist
                        FileUtils.touch(tmp_file_path)
                      }, auto_write_file: auto_write_file, &block)
      end

      def with_existing_tmp_path
        raise NotImplementedError, "#{self.class}#with_existing_tmp_path"
      end

      ##
      # @param preamble_lambda [Lambda, #call] the "function" we should call to prepare the
      #        temporary location before we yield it's location.
      #
      # @param auto_write_file [Boolean] Provided as a testing helper method.  Given that we have
      #        both {#with_new_tmp_path} and {#with_existing_tmp_path}, we want the default to not
      #        automatically perform the write.  But this is something we can easily forget when
      #        working with the {#with_new_tmp_path}
      #
      # @yieldparam tmp_file_path [String]
      def with_tmp_path(preamble_lambda, auto_write_file: false)
        raise ArgumentError, 'Expected a block' unless block_given?

        tmp_file_dir do |tmpdir|
          self.tmp_file_path = File.join(tmpdir, file_name)
          preamble_lambda.call(file_path, tmp_file_path, exist?)
          yield tmp_file_path
          write if auto_write_file
        end
        # TODO: Do we need to ensure this?
        self.tmp_file_path = nil
      end

      ##
      # Write the tmp file to the file_uri
      def write
        raise NotImplementedError, "#{self.class}#write"
      end

      ##
      # @return [TrueClass] when the file exists in this storage
      # @return [FalseClass] when the file does not exist in this storage
      def exist?
        raise NotImplementedError, "#{self.class}#exist?"
      end
      alias exists? exist?

      ##
      #
      # @param extension [String, :same]
      # @param adapter_name [String, StorageAdapters::SAME] what adapter should we use; when given
      #        {StorageAdapters::SAME} use this adapters class as the adapter to create a URI.
      #
      # @see #with_new_extension
      # @see StorageAdapters::SAME
      # @deprecated Shifting towards {#derived_file_from}
      def derived_file(extension:, adapter_name: StorageAdapters::SAME)
        klass = if adapter_name == StorageAdapters::SAME
                  self.class
                else
                  DerivativeRodeo::StorageAdapters::BaseAdapter.load_adapter(adapter_name)
                end
        new_uri = klass.create_uri(path: with_new_extension(extension))
        klass.new(new_uri)
      end

      ##
      # @param template [String]
      # @return [StorageAdapters::BaseAdapter]
      #
      # @see DerivativeRodeo::Services::ConvertUriViaTemplateService
      def derived_file_from(template:)
        klass = DerivativeRodeo::StorageAdapters::BaseAdapter.load_adapter(template)
        klass.build(from_uri: file_path, template: template)
      end

      ##
      # @param extension [String, StorageAdapters::SAME]
      # @return [String] the path for the new extension; when given {StorageAdapters::SAME} re-use
      #         the file's extension.
      def with_new_extension(extension)
        return file_path if extension == StorageAdapters::SAME

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
