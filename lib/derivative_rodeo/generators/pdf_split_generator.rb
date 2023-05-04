# frozen_string_literal: true

module DerivativeRodeo
  module Generators
    ##
    # This class is responsible for splitting each given PDF (e.g. {#input_files}) into one image
    # per page (e.g. {#requisite_files}).  We need to ensure that we have each of those image files
    # in S3/file storage then enqueue those files for processing.
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
      # @return [Array<StorageAdapters::BaseAdapter>]
      def generated_files
        @generated_files ||= with_requisite_files do |image_file|
          output_file = destination(image_file)
          output_file.exist? ? output_file : build_step(in_file: image_file, out_file: output_file)
        end
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
      # @return [Array<StorageAdapters::BaseAdapter>]
      def with_requisite_files
        input_files.map do |input_file|
          input_file.with_existing_tmp_path do |tmp_path|
            image_paths = split_pdf(tmp_path)
            image_paths.map do |image_path|
              image_file = StorageAdapters::FileAdapters.new("file://#{image_path}")
              yield(image_file, image_path)
              image_file
            end
          end
        end.flatten
      end
    end
  end
end
