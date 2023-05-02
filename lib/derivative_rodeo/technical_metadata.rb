# frozen_string_literal: true

module DerivativeRedeo
  TechnicalMetadata = Struct.new(:color, :num_components, :bits_per_component, :width, :height, :content_type,
                                 keyword_init: true) do
    alias_method :number_of_components, :num_components

    def to_hash
      {
        color: color,
        num_components: num_components,
        bits_per_component: bits_per_component,
        width: width,
        height: height,
        content_type: content_type
      }
    end

    def monochrome?
      color.to_s.casecmp('monochrome').zero?
    end
  end
end
