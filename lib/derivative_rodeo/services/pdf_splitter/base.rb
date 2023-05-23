# frozen_string_literal: true

require 'open3'
require 'securerandom'
require 'tmpdir'

module DerivativeRodeo
  module Services
    module PdfSplitter
      ##
      # @param name [String]
      # @return [PdfSplitter::Base]
      def self.for(name)
        klass_name = "#{name.to_s.classify}_page".classify
        "DerivativeRodeo::Services::PdfSplitter::#{klass_name}".constantize
      end

      ##
      # @abstract
      #
      # The purpose of this class is to split the PDF into constituent image files.
      #
      # @see #each
      class Base
        class_attribute :image_extension
        class_attribute :default_dpi, default: 400
        # Should we perform compression logic on the images?
        class_attribute :compression, default: nil
        # What is the image quality we're using?
        class_attribute :quality, default: nil

        class_attribute :gsdevice, instance_accessor: false
        class_attribute :page_count_regexp, instance_accessor: true, default: /^Pages: +(\d+)$/
        ##
        # @api public
        #
        # @param path [String] The path the the PDF
        #
        # @return [Enumerable, Utilities::PdfSplitter::Base]
        def self.call(path, baseid: SureRandom.uuid, tmpdir: Dir.mktmpdir)
          new(path, baseid: baseid, tmpdir: tmpdir)
        end

        ##
        # @param path [String] the path to the source PDF that we're processing.
        # @param baseid [String] used for creating a unique identifier
        # @param tmpdir [String] place to perform the "work" of splitting the PDF.
        # @param pdf_pages_summary [Derivative::Rodeo::PdfPagesSummary] by default we'll
        #        extract this from the given path, but for testing purposes, you might want to
        #        provide a specific summary.
        # @param logger [Logger, #error]
        def initialize(path,
                       baseid: SecureRandom.uuid,
                       # TODO: Do we need to provide the :tmpdir for the application?
                       tmpdir: Dir.mktmpdir,
                       pdf_pages_summary: PagesSummary.extract_from(path: path),
                       logger: DerivativeRodeo.config.logger)
          @baseid = baseid
          @pdfpath = path
          @pdf_pages_summary = pdf_pages_summary
          @tmpdir = tmpdir
          @logger = logger
        end

        attr_reader :logger

        # In creating {#each} we get many of the methods of array operation (e.g. #to_a).
        include Enumerable

        ##
        # @api public
        #
        # @yieldparam [String] the path to the page's tiff.
        def each(&block)
          entries.each(&block)
        end

        # @api private
        def invalid_pdf?
          !pdf_pages_summary.valid?
        end

        attr_reader :pdf_pages_summary, :tmpdir, :baseid, :pdfpath
        private :pdf_pages_summary, :tmpdir, :baseid, :pdfpath

        # @api private
        def gsdevice
          return self.class.gsdevice if self.class.gsdevice

          raise NotImplementedError, "#{self.class}#gsdevice"
        end

        private

        # entries for each page
        def entries
          return @entries if defined? @entries

          @entries = Array.wrap(gsconvert)
        end

        def output_base
          @output_base ||= File.join(tmpdir, "#{baseid}-page%d.#{image_extension}")
        end

        def gsconvert
          # NOTE: you must call gsdevice before compression, as compression is
          # updated during the gsdevice call.
          file_names = []

          Open3.popen3(gsconvert_cmd(output_base)) do |_stdin, stdout, stderr, _wait_thr|
            err = stderr.read
            logger.error "#{self.class}#gsconvert encountered the following error with `gs': #{err}" if err.present?

            page_number = 1
            stdout.read.split("\n").each do |line|
              next unless line.start_with?('Page ')

              file_names << format(output_base, page_number)
              page_number += 1
            end
          end

          file_names
        end

        def create_file_name(line:, page_number:); end

        def gsconvert_cmd(output_base)
          @gsconvert_cmd ||= begin
                               cmd = "gs -dNOPAUSE -dBATCH -sDEVICE=#{gsdevice} -dTextAlphaBits=4"
                               cmd += " -sCompression=#{compression}" if compression?
                               cmd += " -dJPEGQ=#{quality}" if quality?
                               cmd += " -sOutputFile=#{output_base} -r#{ppi} -f #{pdfpath}"
                               cmd
                             end
        end

        def pagecount
          return @pagecount if defined? @pagecount

          cmd = "pdfinfo #{pdfpath}"
          Open3.popen3(cmd) do |_stdin, stdout, stderr, _wait_thr|
            err = stderr.read
            logger.error "#{self.class}#pagecount encountered the following error with `pdfinfo': #{err}" if err.present?
            output = stdout.read
            raise "pdfinfo failed to return output for #{pdfpath} - #{err}" if output.blank?
            match = page_count_regexp.match(output)

            @pagecount = match[1].to_i
          end
          @pagecount
        end

        def ppi
          if looks_scanned?
            # For scanned media, defer to detected image PPI:
            pdf_pages_summary.ppi
          else
            # 400 dpi for something that does not look like scanned media:
            default_dpi
          end
        end

        def looks_scanned?
          max_image_px = pdf_pages_summary.width * pdf_pages_summary.height
          # single 10mp+ image per page?
          single_image_per_page? && max_image_px > 1024 * 1024 * 10
        end

        def single_image_per_page?
          pdf_pages_summary.page_count == pagecount
        end
      end
    end
  end
end
