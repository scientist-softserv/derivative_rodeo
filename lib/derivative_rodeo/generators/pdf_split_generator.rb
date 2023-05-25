# frozen_string_literal: true
require 'derivative_rodeo/generators/concerns/copy_file_concern'

module DerivativeRodeo
  module Generators
    ##
    # This class is responsible for splitting each given PDF (e.g. {#input_files}) into one image
    # per page (e.g. {#with_each_requisite_location_and_tmp_file_path}).  We need to ensure that we
    # have each of those image files in S3/file storage then enqueue those files for processing.
    class PdfSplitGenerator < BaseGenerator
      ##
      # There is a duplication  of the splitter name.
      #
      # @see #pdf_splitter_name
      self.output_extension = "tiff"

      include CopyFileConcern

      ##
      # @param basename [String] The given PDF file's base name (e.g. "hello.pdf" would have a base name of
      #        "hello").
      #
      # @return [String] A template for the filenames of the images produced by Ghostscript.
      #
      # @note This must include "%d" in the returning value, as that is how Ghostscript will assign
      # the page number.
      #
      # @note I have extracted this function to make it abundantly clear the expected filename of
      # each split image.
      def image_file_basename_template(basename:)
        # TODO: Rather urgently we need to decide if this is a reasonable format?  Do we want to
        # have subfolders instead?  Will that make it easier to find things.
        "#{basename}-page%d.#{output_extension}"
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
      # @yieldparam image_location [StorageLocations::FileLocation] the file and adapter logic.
      # @yieldparam image_path [String] where to find this file in the tmp space
      #
      # @see BaseGenerator#with_each_requisite_location_and_tmp_file_path for further discussion
      def with_each_requisite_location_and_tmp_file_path
        input_files.each do |input_location|
          input_location.with_existing_tmp_path do |input_tmp_file_path|
            Services::PdfSplitter.call(
              input_tmp_file_path,
              image_extension: output_extension,
              image_file_basename_template: image_file_basename_template(basename: input_location.file_basename)
            ).each do |image_path|
              image_location = StorageLocations::FileLocation.new("file://#{image_path}")
              yield(image_location, image_path)
            end
          end
        end
      end
    end
  end
end
