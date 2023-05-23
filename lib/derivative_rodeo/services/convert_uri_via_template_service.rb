# frozen_string_literal: true

module DerivativeRodeo
  module Services
    ##
    #
    # A service to convert an array of :from_uris to :to_uris via a :template.
    #
    # @see .call
    class ConvertUriViaTemplateService
      DIR_PARTS_REPLACEMENT_REGEXP = %r{\{\{\s*dir_parts\[(?<left>\-?\d+)\.\.(?<right>\-?\d+)\]\s*\}\}}.freeze
      FILENAME_REPLACEMENT_REGEXP = %r{\{\{\s*filename\s*\}\}}.freeze
      BASENAME_REPLACEMENT_REGEXP = %r{\{\{\s*basename\s*\}\}}.freeze
      EXTENSION_REPLACEMENT_REGEXP = %r{\{\{\s*extension\s*\}\}}.freeze
      SCHEME_REPLACEMENT_REGEXP = %r{\{\{\s*scheme* \}\}}.freeze
      SCHEME_FOR_URI_REGEXP = %r{^(?<from_scheme>[^:]+)://}.freeze
      attr_accessor :from_uri, :template, :adapter, :separator, :uri, :from_scheme, :path, :parts, :dir_parts, :filename, :basename, :extension, :template_without_query, :template_query

      ##
      # Convert the given :from_uris to a different list of uris based on the given :template.
      #
      # Components of the template:
      #
      # - basename :: the file's basename without extension
      # - extension :: the file's extension with the period
      # - dir_parts :: the directory parts in which the file exists; excludes the scheme
      # - filename :: a convenience that could be represented as `basename.extension`
      # - scheme :: a convenience that could be represented as `basename.extension`
      #
      # The specs demonstrate the use cases.
      #
      # @param from_uri [String] Of the form "scheme://dir/parts/basename.extension"
      # @param template [String] Another URI that may contain path_parts or scheme template values.
      # @param adapter [StorageLocations::Location]
      # @param separator [String]
      #
      # @return [String]
      #
      # @example
      #   DerivativeRodeo::Services::ConvertUriViaTemplateService.call(
      #     from_uris: ["file:///path1/A/file.pdf", "file:///path2/B/file.pdf"],
      #     template: "file:///dest1/{{dir_parts[-2..-1]}}/{{filename}}")
      #   => ["file:///dest1/path2/A/file.pdf", "file:///dest1/path2/B/file.pdf"]
      #
      #   DerivativeRodeo::Services::ConvertUriViaTemplateService.call(
      #     from_uris: ["file:///path1/A/file.pdf", "aws:///path2/B/file.pdf"],
      #     template: "file:///dest1/{{dir_parts[-1..-1]}}/{{ filename }}")
      #   => ["file:///dest1/A/file.pdf", "aws:///dest1/B/file.pdf"]
      def self.call(from_uri:, template:, adapter: nil, separator: "/")
        new(from_uri: from_uri, template: template, adapter: adapter, separator: separator).call
      end

      def initialize(from_uri:, template:, adapter: nil, separator: "/")
        @from_uri = from_uri
        @template = template
        @adapter = adapter
        @separator = separator

        @uri, _query = from_uri.split("?")
        @from_scheme, @path = uri.split("://")
        @parts = @path.split(separator)
        @dir_parts = @parts[0..-2]
        @filename = @parts[-1]
        @basename = File.basename(@filename, ".*")
        @extension = File.extname(@filename)

        @template_without_query, @template_query = template.split("?")
      end

      def call
        to_uri = template_without_query.gsub(DIR_PARTS_REPLACEMENT_REGEXP) do |text|
          # The yielded value does not include capture regions.  So I'm re-matching things.
          # capture region to handle this specific thing.
          match = DIR_PARTS_REPLACEMENT_REGEXP.match(text)
          dir_parts[(match[:left].to_i)..(match[:right].to_i)].join(separator)
        end

        to_uri = to_uri.gsub(SCHEME_REPLACEMENT_REGEXP, (adapter&.scheme || from_scheme))
        to_uri = to_uri.gsub(EXTENSION_REPLACEMENT_REGEXP, extension)
        to_uri = to_uri.gsub(BASENAME_REPLACEMENT_REGEXP, basename)
        to_uri.gsub!(FILENAME_REPLACEMENT_REGEXP, filename)
        to_uri = "#{to_uri}?#{template_query}" if template_query
        to_uri
      end
    end
  end
end
