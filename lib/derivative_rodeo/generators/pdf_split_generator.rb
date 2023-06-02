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
      # @note I have extracted this function to make it abundantly clear the expected location
      # each split image.  Further there is an interaction in this
      #
      # @see #existing_page_locations
      def image_file_basename_template(basename:)
        "#{basename}/pages/#{basename}--page-%d.#{output_extension}"
      end

      ##
      # We want to check the output location and pre-processed location for the existence of already
      # split pages.  This method checks both places.
      #
      # @param input_location [StorageLocations::BaseLocation]
      #
      # @return [Enumerable<StorageLocations::BaseLocation>] the files at the given :input_location
      #         with :tail_glob.
      #
      # @note There is relation to {Generators::BaseGenerator#destination} and this method.
      #
      # @note The tail_glob is in relation to the {#image_file_basename_template}
      def existing_page_locations(input_location:)
        # See image_file_basename_template
        tail_glob = "#{input_location.file_basename}/pages/*.#{output_extension}"

        output_locations = input_location.derived_file_from(template: output_location_template).globbed_tail_locations(tail_glob: tail_glob)
        return output_locations if output_locations.count.positive?

        return [] if preprocessed_location_template.blank?

        input_location.derived_file_from(template: preprocessed_location_template).globbed_tail_loations(tail_glob: tail_glob)
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
      # @note This function makes a concession; namely that if it encounters any
      # {#existing_page_locations} it will use all of that result as the entire number of pages.
      # We could make this smarter but at the moment we're deferring on that.
      #
      # @see BaseGenerator#with_each_requisite_location_and_tmp_file_path for further discussion
      #
      # rubocop:disable Metrics/MethodLength
      def with_each_requisite_location_and_tmp_file_path
        input_files.each do |input_location|
          input_location.with_existing_tmp_path do |input_tmp_file_path|
            ## We want a single call for a directory listing of the image_file_basename_template
            generated_files = existing_page_locations(input_location: input_location)

            if generated_files.count.zero?
              generated_files = Services::PdfSplitter.call(
                input_tmp_file_path,
                image_extension: output_extension,
                image_file_basename_template: image_file_basename_template(basename: input_location.file_basename)
              )
            end

            generated_files.each do |image_path|
              image_location = StorageLocations::FileLocation.new("file://#{image_path}")
              yield(image_location, image_path)
            end
          end
        end
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
