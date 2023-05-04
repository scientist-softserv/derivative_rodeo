# frozen_string_literal: true

module DerivativeRodeo
  module Generators
    ##
    # This class is responsible for splitting each given PDF (e.g. {#input_files}) into one image
    # per page (e.g. {#with_each_requisite_file_and_tmp_path}).  We need to ensure that we have each
    # of those image files in S3/file storage then enqueue those files for processing.
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
      # @param in_tmp_path [String] the path to an image split off from one of the given PDFs.
      # @param out_file [StorageAdapters::BaseAdapter]
      # @return [StorageAdapters::BaseAdapter]
      def build_step(out_file:, in_tmp_path:, **)
        # TODO: Implement copy
        copy(in_tmp_path, out_file)
      end

      ##
      # @api public
      #
      # Take the given PDF(s) and into one image per page.  Remember that the URL should account for
      # the page number.
      #
      # When we have two PDFs (10 pages and 20 pages respectively), we will have 30 requisite files;
      # the files must have URLs that associate with their respective parent PDFs.
      #
      # @yieldparam image_file [StorageAdapters::FileAdapters] the file and adapter logic.
      # @yieldparam image_path [String] where to find this file in the tmp space
      #
      # @return [Array<StorageAdapters::BaseAdapter>]
      def with_each_requisite_file_and_tmp_path
        files = []
        input_files.each do |input_file|
          input_file.with_existing_tmp_path do |_tmp_path|
            # TODO
            # alto_pdf(tmp_path)
            # image_paths = split_pdf(tmp_path)
            image_paths.each do |image_path|
              image_file = StorageAdapters::FileAdapters.new("file://#{image_path}")
              yield(image_file, image_path)
              files << image_file
            end
          end
        end
        files
      end
    end
  end
end
