# frozen_string_literal: true

module DerivativeRodeo
  module Services
    ##
    #
    # A service to convert an array of :from_uris to :to_uris via a :template.
    #
    # @see .call
    class ConvertUrisWithUriTemplateService
      SCHEME_PREFIX_REGEXP = %r{^(?<scheme>\w+://)}.freeze
      PATH_PARTS_REPLACEMENT_REGEXP = %r{\{\{ *path_parts\[(?<left>\-?\d+)\.\.(?<right>\-?\d+)\] *\}\}}.freeze
      SCHEME_REPLACEMENT_REGEXP = %r{^\{\{ *from_scheme *\}\}}.freeze

      ##
      # Convert the given :from_uris to a different list of uris based on the given :template.
      #
      # @param from_uris [Array<String>]
      # @param template [String] Another URI that may contain path_parts or scheme template values.
      # @param separator [String]
      #
      # @return [Array<String>]
      #
      # @example
      #   DerivativeRodeo::Services::ConvertUrisWithUriTemplateService.call(
      #     from_uris: ["file:///path1/A/file.pdf", "file:///path2/B/file.pdf"],
      #     template: "file:///dest1/{{path_parts[-2..-1]}}")
      #   => ["file:///dest1/A/file.pdf", "file:///dest1/B/file.pdf"]
      #
      #   DerivativeRodeo::Services::ConvertUrisWithUriTemplateService.call(
      #     from_uris: ["file:///path1/A/file.pdf", "aws:///path2/B/file.pdf"],
      #     template: "{{scheme}}:///dest1/{{path_parts[-2..-1]}}")
      #   => ["file:///dest1/A/file.pdf", "aws:///dest1/B/file.pdf"]
      def self.call(from_uris:, template:, separator: "/")
        from_uris.map do |from_uri|
          parts = from_uri.sub(SCHEME_PREFIX_REGEXP, "").split(separator)

          # rubocop:disable Style/MultilineBlockChain
          template.gsub(PATH_PARTS_REPLACEMENT_REGEXP) do |text|
            # The yielded value does not include capture regions.  So I'm re-matching things.
            # capture region to handle this specific thing.
            match = PATH_PARTS_REPLACEMENT_REGEXP.match(text)
            parts[(match[:left].to_i)..(match[:right].to_i)].join(separator)
          end.gsub(SCHEME_REPLACEMENT_REGEXP) do |_text|
            SCHEME_PREFIX_REGEXP.match(from_uri)[:scheme]
          end
          # rubocop:enable Style/MultilineBlockChain
        end
      end
    end
  end
end
