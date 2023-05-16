# frozen_string_literal: true
require 'derivative_rodeo/generators/concerns/copy_file_concern'

module DerivativeRodeo
  module Generators
    ##
    # This class is responsible for splitting each given PDF (e.g. {#input_files}) into one image
    # per page (e.g. {#with_each_requisite_target_and_tmp_file_path}).  We need to ensure that we
    # have each of those image files in S3/file storage then enqueue those files for processing.
    class PdfSplitGenerator < BaseGenerator
      ##
      # There is a duplication  of the splitter name.
      #
      # @see #pdf_splitter_name
      self.output_extension = "tiff"

      include CopyFileConcern

      ##
      # @param name [#to_s] Convert the given name into the resulting {Services::PdfSplitter::Base}.
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
      # @api public
      #
      # Take the given PDF(s) and into one image per page.  Remember that the URL should account for
      # the page number.
      #
      # When we have two PDFs (10 pages and 20 pages respectively), we will have 30 requisite files;
      # the files must have URLs that associate with their respective parent PDFs.
      #
      # @yieldparam image_target [StorageTargets::FileTarget] the file and adapter logic.
      # @yieldparam image_path [String] where to find this file in the tmp space
      #
      # @see BaseGenerator#with_each_requisite_target_and_tmp_file_path for further discussion
      def with_each_requisite_target_and_tmp_file_path
        input_files.each do |input_target|
          input_target.with_existing_tmp_path do |input_tmp_file_path|
            image_paths = pdf_splitter.call(input_tmp_file_path, baseid: input_target.file_basename, tmpdir: File.dirname(input_tmp_file_path))
            image_paths.each do |image_path|
              image_target = StorageTargets::FileTarget.new("file://#{image_path}")
              yield(image_target, image_path)
            end
          end
        end
      end
    end
  end
end
