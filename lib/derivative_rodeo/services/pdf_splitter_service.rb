# frozen_string_literal: true

module DerivativeRodeo
  module Services
    module PdfSplitterService
      ##
      # @api public
      #
      # Find the {PdfSplitter::Base} with the given name.
      #
      # @param name [#to_s]
      # @return [PdfSplitter::Base]
      def self.for(name)
        klass_name = "#{name.to_s.classify}_page".classify
        "DerivativeRodeo::Services::PdfSplitter::#{klass_name}".constantize
      end
    end
  end
end
