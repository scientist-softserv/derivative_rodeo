# frozen_string_literal: true

require 'tmpdir'

module DerivativeRodeo
  module StorageLocations
    ##
    # When the output location is the same type of location as "this" location, we indicate that via
    # the SAME constant.
    SAME = :same

    ##
    # The base location for storing files.
    #
    # - dir :: is the directory path
    # - path :: is the full file path
    # - uri :: is the full file path plus the uri prefix parts
    #
    # A location represents a pointer to a storage location.  The {#exist?} method can answer if a
    # file exists at the path.
    #
    # rubocop:disable Metrics/ClassLength
    class BaseLocation
      @locations = []

      ##
      # @return [Array<String>]
      def self.locations
        @locations ||= []
      end

      def self.inherited(subclass)
        locations << subclass.location_name
        super
      end

      ##
      # @return [String]
      def self.location_name
        to_s.demodulize.underscore.sub(/_location$/, '')
      end

      class << self
        alias scheme location_name

        delegate :config, to: DerivativeRodeo
      end

      ##
      # @param location_name [String]
      #
      # @return [Class]
      def self.load_location(location_name)
        location_name = location_name.split("://").first
        raise Errors::StorageLocationNotFoundError.new(location_name: location_name) unless locations.include?(location_name)
        "DerivativeRodeo::StorageLocations::#{location_name.to_s.classify}Location".constantize
      end

      ##
      # @param file_uri [String] of the form scheme://arbitrary-stuff
      #
      # @return [BaseLocation]
      def self.from_uri(file_uri)
        location_name = file_uri.split('://').first
        raise Errors::StorageLocationMissing.new(file_uri: file_uri) if location_name.blank?

        load_location(location_name).new(file_uri)
      end

      ##
      # Registers the location with the main StorageLocation class to it can be used
      #
      # @param location_name [String]
      def self.register_location(location_name)
        return if DerivativeRodeo::StorageLocations::BaseLocation.locations.include?(location_name.to_s)

        DerivativeRodeo::StorageLocations::BaseLocation.locations << location_name.to_s
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
      # Build a {StorageLocations::BaseLocation} by converting the :from_uri with the :template via
      # the given :service.
      #
      # @param from_uri [String]
      # @param template [String]
      # @param service [#call, Module<DerivativeRodeo::Services::ConvertUriViaTemplateService>]
      #
      # @return [StorageLocations::BaseLocation]
      def self.build(from_uri:, template:, service: DerivativeRodeo::Services::ConvertUriViaTemplateService, **options)
        # HACK: Ensuring that we have the correct scheme.  Maybe this is a hack?
        from_uri = "#{scheme}://#{from_uri}" unless from_uri.start_with?("#{scheme}://")
        to_uri = service.call(from_uri: from_uri, template: template, adapter: self, **options)
        new(to_uri)
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

      ##
      # @param file_uri [String] a URI to the file's location; this is **not** a templated URI (as
      #        described in {DerivativeRodeo::Services::ConvertUriViaTemplateService}
      # @param config [DerivativeRodeo::Configuration]
      def initialize(file_uri, config: DerivativeRodeo.config)
        @file_uri = file_uri
        @config = config
      end

      attr_accessor :tmp_file_path
      private :tmp_file_path=, :tmp_file_path

      attr_reader :config, :file_uri

      ##
      # @param auto_write_file [Boolean] Provided as a testing helper method.
      #
      # @yieldparam tmp_file_path [String]
      #
      # @return [StorageLocations::BaseLocation]
      # @see with_tmp_path
      def with_new_tmp_path(auto_write_file: true, &block)
        with_tmp_path(lambda { |_file_path, tmp_file_path, exist|
                        FileUtils.rm_rf(tmp_file_path) if exist
                        FileUtils.touch(tmp_file_path)
                      }, auto_write_file: auto_write_file, &block)
      end

      ##
      # @yieldparam tmp_file_path [String]
      # @return [StorageLocations::BaseLocation]
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
      #
      # @return [StorageLocations::BaseLocation]
      def with_tmp_path(preamble_lambda, auto_write_file: false)
        raise ArgumentError, 'Expected a block' unless block_given?

        tmp_file_dir do |tmpdir|
          self.tmp_file_path = File.join(tmpdir, file_dir, file_name)
          FileUtils.mkdir_p(File.dirname(tmp_file_path))
          preamble_lambda.call(file_path, tmp_file_path, exist?)
          yield tmp_file_path
          write if auto_write_file
        end
        # TODO: Do we need to ensure this?
        self.tmp_file_path = nil

        # In returning self we again remove the need for those calling #with_new_tmp_path,
        # #with_tmp_path, and #with_new_tmp_path to remember to return the current Location.
        # In other words removing the jagged edges of the code.
        self
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
      # @param template [String]
      # @return [StorageLocations::BaseLocation]
      #
      # @see DerivativeRodeo::Services::ConvertUriViaTemplateService
      def derived_file_from(template:, **options)
        klass = DerivativeRodeo::StorageLocations::BaseLocation.load_location(template)
        klass.build(from_uri: file_path, template: template, **options)
      end

      ##
      # When you have a known location and want to check for files that are within that location,
      # use the {#matching_locations_in_file_dir} method.  In the case of {Generators::PdfSplitGenerator} we
      # need to know the path to all of the image files we "split" off of the given PDF.
      #
      # We can use the :file_path as the prefix the given :tail_glob as the suffix for a "fully
      # qualified" Dir.glob type search.
      #
      # @param tail_regexp [Regexp]
      #
      # @return [Enumerable<StorageLocations::BaseLocation>] the locations of the files; an empty
      #         array when there are none.
      def matching_locations_in_file_dir(tail_regexp:)
        raise NotImplementedError, "#{self.class}#matching_locations_in_file_dir"
      end

      ##
      # @param extension [String, StorageLocations::SAME]
      # @return [String] the path for the new extension; when given {StorageLocations::SAME} re-use
      #         the file's extension.
      def with_new_extension(extension)
        return file_path if extension == StorageLocations::SAME

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

      def file_extension
        @file_extension ||= File.extname(file_path)
      end

      def file_basename
        @file_basename ||= File.basename(file_path, file_extension)
      end

      def tmp_file_dir(&block)
        raise ArgumentError, 'Expected a block' unless block_given?

        Dir.mktmpdir(&block)
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end

Dir.glob(File.join(__dir__, '**/*')).sort.each do |location|
  require location unless File.directory?(location) || location.match?('base_location')
end
