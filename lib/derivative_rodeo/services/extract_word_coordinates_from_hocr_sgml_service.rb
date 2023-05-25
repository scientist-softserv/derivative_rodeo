# frozen_string_literal: true

require 'forwardable'
require 'json'
require 'nokogiri'

module DerivativeRodeo
  module Services
    ##
    # Responsible for converting an SGML string into JSON coordinates
    class ExtractWordCoordinatesFromHocrSgmlService
      ##
      # @param sgml [String] The SGML (e.g. XML or HTML) text of a HOCR file.
      # @return [String] A JSON document
      def self.call(sgml)
        new(sgml)
      end

      ##
      # Construct with either path or HTML [String]
      #
      # @param html [String] either an XML string or a path to a file.
      def initialize(html)
        @source = xml?(html) ? html : File.read(html)
        @doc_stream = DocStream.new
        parser = Nokogiri::HTML::SAX::Parser.new(@doc_stream)
        parser.parse(@source)
      end
      attr_reader :doc_stream, :source

      delegate :text, :width, :height, :words, to: :doc_stream

      # Output JSON flattened word coordinates
      #
      # @return [String] JSON serialization of flattened word coordinates
      def to_json
        @to_json ||= WordCoordinates.to_json(
          words: doc_stream.words,
          width: doc_stream.width,
          height: doc_stream.height
        )
      end
      alias json to_json

      # Output plain text, keeping the method calls consistent with so calling this #to_text
      #
      # @return [String] plain text of OCR'd document
      def to_text
        @to_text ||= doc_stream.text
      end

      private

      def xml?(xml)
        xml.lstrip.start_with?('<')
      end

      # SAX Document Stream class to gather text and word tokens from hOCR
      class DocStream < Nokogiri::XML::SAX::Document
        attr_accessor :text, :words, :width, :height

        def initialize
          super()
          # plain text buffer:
          @text = ''
          # list of word hash, containing word+coord:
          @words = []
          # page width and height to be found in hOCR for `div.ocr_page`
          @width = nil
          @height = nil
          # to hold current word data state across #start_element, #characters,
          #   and #end_element methods (to associate word with coordinates).
          @current = nil
          # to preserve element classname from start to use by #end_element
          @element_class_name = nil
        end

        # Return coordinates from `span.ocrx_word` element attribute hash
        #
        # @param attrs [Hash] hash with hOCR `span.ocrx_word` element attributes
        # @return [Array] Array of position x, y, width, height in px.
        def s_coords(attrs)
          element_title = attrs['title']
          bbox = element_title.split(';')[0].split('bbox ')[-1]
          x1, y1, x2, y2 = bbox.split(' ').map(&:to_i)
          height = y2 - y1
          width = x2 - x1
          hpos = x1
          vpos = y1
          [hpos, vpos, width, height]
        end

        # Consider element for processing?
        #   - `div.ocr_page` — to get page width/height
        #   - `span.ocr_line` — to help make plain text readable
        #   - `span.ocrx_word` — for word-coordinate JSON and plain text word
        # @param name [String] Element name
        # @param class_name [String] HTML class name
        # @return [Boolean] true if element should be processed; otherwise false
        def consider?(name, class_name)
          selector = "#{name}.#{class_name}"
          ['div.ocr_page', 'span.ocr_line', 'span.ocrx_word'].include?(selector)
        end

        def start_word(attrs)
          @current = {}
          # will be replaced during #characters method call:
          @current[:word] = nil
          @current[:coordinates] = s_coords(attrs)
        end

        def start_page(attrs)
          title = attrs['title']
          fields = title.split(';')
          bbox = fields[1].split('bbox ')[-1].split(' ').map(&:to_i)
          # width and height:
          @width = bbox[2]
          @height = bbox[3]
        end

        def word_complete?
          return false if @current.nil?
          coords = @current[:coordinates]
          @current[:word].present? && coords.size == 4
        end

        def end_word
          # add trailing space to plaintext buffer for between words:
          @text += ' '
          @words.push(@current) if word_complete?
          @current = nil # clear the current word
        end

        def end_line
          # strip trailing whitespace
          @text.strip!
          # then insert a line break
          @text += "\n"
        end

        # Callback for element start, ignores elements except for:
        #   - `div.ocr_page` — to get page width/height
        #   - `span.ocr_line` — to help make plain text readable
        #   - `span.ocrx_word` — for word-coordinate JSON and plain text word
        #
        # @param name [String] element name.
        # @param attrs [Array] Array of key, value pair Arrays.
        def start_element(name, attrs = [])
          attributes = attrs.to_h
          @element_class_name = attributes['class']
          return unless consider?(name, @element_class_name)
          start_word(attributes) if @element_class_name == 'ocrx_word'
          start_page(attributes) if @element_class_name == 'ocr_page'
        end

        def characters(value)
          return if @current.nil?
          return if @current[:coordinates].nil?
          @current[:word] ||= ''
          @current[:word] += value
          @text += value
        end

        # Callback for element end; at this time, flush word coordinate state
        #   for current word, and append line endings to plain text:
        #
        # @param name [String] element name.
        def end_element(name)
          if name == 'span'
            end_word if @element_class_name == 'ocrx_word'
            @text += "\n" if @element_class_name.nil?
          end
          @element_class_name = nil
        end

        # Callback for completion of parsing hOCR, used to normalize generated
        #   text content (strip unneeded whitespace incidental to output).
        def end_document
          # postprocess @text to remove trailing spaces on lines
          @text = @text.split("\n").map(&:strip).join("\n")
          # remove excess line break
          @text.gsub!(/\n+/, "\n")
          @text.delete("\r")
          # remove trailing whitespace at end of buffer
          @text.strip!
        end
      end

      class WordCoordinates
        ##
        # @api public
        #
        # @param words [Array<Hash>] an array of hash objects that have the keys `:word` and `:coordinates`.
        # @param width [Integer] the width of the "canvas" on which the words appear.
        # @param height [Integer] the height of the "canvas" on which the words appear.
        #
        # @return [String] a JSON encoded string.
        def self.to_json(words:, width: nil, height: nil)
          new(words: words, width: width, height: height).to_json
        end

        def initialize(words:, width:, height:)
          @words = words
          @width = width
          @height = height
        end
        attr_reader :words, :width, :height

        # Output JSON flattened word coordinates
        #
        # @return [String] JSON serialization of flattened word coordinates
        def to_json
          coordinates = {}
          words.each do |word|
            word_chars = word[:word]
            word_coords = word[:coordinates]
            if coordinates[word_chars]
              coordinates[word_chars] << word_coords
            else
              coordinates[word_chars] = [word_coords]
            end
          end
          payload = { width: width, height: height, coords: coordinates }
          JSON.generate(payload)
        end
      end
    end
  end
end
