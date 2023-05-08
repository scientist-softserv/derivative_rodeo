# frozen_string_literal: true

module DerivativeRodeo
  module Services
    ##
    #
    # A service to convert an array of :from_uris to :to_uris via a :template.
    #
    # @see .call
    class ConvertUrisWithUriTemplateService
      DIR_PARTS_REPLACEMENT_REGEXP = %r{\{\{ *dir_parts\[(?<left>\-?\d+)\.\.(?<right>\-?\d+)\] *\}\}}.freeze
      FILENAME_REPLACEMENT_REGEXP = %r{\{\{ *filename *\}\}}.freeze
      BASENAME_REPLACEMENT_REGEXP = %r{\{\{ *basename *\}\}}.freeze
      EXTENSION_REPLACEMENT_REGEXP = %r{\{\{ *extension *\}\}}.freeze

      ##
      # Convert the given :from_uris to a different list of uris based on the given :template.
      #
      # Components of the template:
      #
      # - basename :: the file's basename without extension
      # - extension :: the file's extension with the period
      # - dir_parts :: the directory parts in which the file exists; excludes the scheme
      # - filename :: a convenience that could be represented as `basename.extension`
      #
      # The specs demonstrate the use cases.
      #
      # @param from_uri [String] Of the form "scheme://dir/parts/basename.extension"
      # @param template [String] Another URI that may contain path_parts or scheme template values.
      # @param separator [String]
      #
      # @return [String]
      #
      # @example
      #   DerivativeRodeo::Services::ConvertUrisWithUriTemplateService.call(
      #     from_uris: ["file:///path1/A/file.pdf", "file:///path2/B/file.pdf"],
      #     template: "file:///dest1/{{dir_parts[-2..-1]}}/{{filename}}")
      #   => ["file:///dest1/path2/A/file.pdf", "file:///dest1/path2/B/file.pdf"]
      #
      #   DerivativeRodeo::Services::ConvertUrisWithUriTemplateService.call(
      #     from_uris: ["file:///path1/A/file.pdf", "aws:///path2/B/file.pdf"],
      #     template: "file:///dest1/{{dir_parts[-1..-1]}}/{{ filename }}")
      #   => ["file:///dest1/A/file.pdf", "aws:///dest1/B/file.pdf"]
      def self.call(from_uri:, template:, separator: "/")
        _scheme, path = from_uri.split("://")
        parts = path.split(separator)
        dir_parts = parts[0..-2]
        filename = parts[-1]
        basename = File.basename(filename, ".*")
        extension = File.extname(filename)

        to_uri = template.gsub(DIR_PARTS_REPLACEMENT_REGEXP) do |text|
          # The yielded value does not include capture regions.  So I'm re-matching things.
          # capture region to handle this specific thing.
          match = DIR_PARTS_REPLACEMENT_REGEXP.match(text)
          dir_parts[(match[:left].to_i)..(match[:right].to_i)].join(separator)
        end

        to_uri = to_uri.gsub(EXTENSION_REPLACEMENT_REGEXP, extension)
        to_uri = to_uri.gsub(BASENAME_REPLACEMENT_REGEXP, basename)
        to_uri.gsub(FILENAME_REPLACEMENT_REGEXP, filename)
      end
    end
  end
end
