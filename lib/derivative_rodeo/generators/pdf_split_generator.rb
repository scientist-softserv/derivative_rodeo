# frozen_string_literal: true

module DerivativeRodeo
  module Generators
    ##
    # This class is responsible for splitting each given PDF (e.g. {#input_files}) into one image
    # per page (e.g. {#requisite_files}).  We need to ensure that we have each of those image files
    # in storage.
    class PdfSplitGenerator < BaseGenerator
      ##
      # There is a duplication  of the splitter name.
      #
      # @see #pdf_splitter_name
      self.output_extension = "tiff"

      ##
      # @param name [Symbol]
      #
      # @return [#call, Services::PdfSplitter::Base]
      def pdf_splitter(name: pdf_splitter_name)
        @pdf_splitter ||= Services::PdfSplitter.for(name)
      end

      ##
      # @return [Symbol]
      #
      # @see .output_extension
      def pdf_splitter_name
        output_extension.to_s.split(".").last.to_sym
      end

      ##
      # The :in_file will be an image (split off from the PDF).  The :out_file should be written to
      # the same adapter as where the PDF came from.  Question, is that correct?  How do we know the
      # PDF was from a queue?
      #
      # @param in_file [StorageAdapters::BaseAdapter]
      # @param out_file [StorageAdapters::BaseAdapter]
      # @return [StorageAdapters::BaseAdapter]
      def build_step(in_file:, out_file:); end

      ##
      # @api public
      #
      # Take the given PDF(s) and into one image per page.  Remember that the URL should account for
      # the page number.
      #
      # When we have two PDFs (10 pages and 20 pages respectively), we will have 30 requisite files;
      # the files must have URLs that associate with their respective parent PDFs.
      #
      # @return [Array<StorageAdapters::BaseAdapter>]
      def requisite_files; end
    end
  end
end
