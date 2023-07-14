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
      # A helper method for downstream implementations to ask if this file is perhaps split from a
      # PDF.
      #
      # @param filename [String]
      # @param extension [String] the extension (either with or without the leading period); if none
      #        is provided use the extension of the given :filename.
      # @return [TrueClass] when the file name likely represents a file split from a PDF.
      # @return [FalseClass] when the file name does not, by convention, represent a file split from
      #         a PDF.
      #
      # @see #image_file_basename_template
      def self.filename_for_a_derived_page_from_a_pdf?(filename:, extension: nil)
        extension ||= File.extname(filename)

        # Strip the leading period from the extension.
        extension = extension[1..-1] if extension.start_with?('.')
        regexp = %r{--page-\d+\.#{extension}$}
        !!regexp.match(filename)
      end

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
      # @see .filename_for_a_derived_page_from_a_pdf?
      def image_file_basename_template(basename:)
        "#{basename}--page-%d.#{output_extension}"
      end

      ##
      # We want to check the output location and pre-processed location for the existence of already
      # split pages.  This method checks both places.
      #
      # @param input_location [StorageLocations::BaseLocation]
      #
      # @return [Enumerable<StorageLocations::BaseLocation>] the files at the given :input_location
      #         with :tail_regexp.
      #
      # @note There is relation to {Generators::BaseGenerator#destination} and this method.
      #
      # @note The tail_glob is in relation to the {#image_file_basename_template}
      def existing_page_locations(input_location:)
        # See image_file_basename_template
        tail_regexp = %r{#{input_location.file_basename}--page-\d+\.#{output_extension}$}

        output_locations = input_location.derived_file_from(template: output_location_template).matching_locations_in_file_dir(tail_regexp: tail_regexp)
        return output_locations if output_locations.count.positive?

        return [] if preprocessed_location_template.blank?

        input_location.derived_file_from(template: preprocessed_location_template).matching_locations_in_file_dir(tail_regexp: tail_regexp)
      end

      ##
      # @api public
      #
      # @param splitter [#call]
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
      # rubocop:disable Metrics/AbcSize
      def with_each_requisite_location_and_tmp_file_path(splitter: Services::PdfSplitter)
        input_files.each do |input_location|
          input_location.with_existing_tmp_path do |input_tmp_file_path|
            existing_locations = existing_page_locations(input_location: input_location)

            if existing_locations.count.positive?
              logger.info("#{self.class}##{__method__} found #{existing_locations.count} file(s) at existing split location for #{input_location.file_uri.inspect}.")
              existing_locations.each_with_index do |location, index|
                logger.info("#{self.class}##{__method__} found ##{index} split file #{location.file_path.inspect} for #{input_location.file_uri.inspect}.")
                yield(location, location.file_path)
              end
            else
              logger.info("#{self.class}##{__method__} did not find at existing location split files for #{input_location.file_uri.inspect}.  Proceeding with #{splitter}.call")
              # We're going to need to create the files and "cast" them to locations.
              splitter.call(
                input_tmp_file_path,
                image_extension: output_extension,
                image_file_basename_template: image_file_basename_template(basename: input_location.file_basename)
              ).each_with_index do |image_path, index|
                logger.info("#{self.class}##{__method__} generated (via #{splitter}.call) ##{index} split file #{image_path.inspect} for #{input_location.file_uri.inspect}.")
                image_location = StorageLocations::FileLocation.new("file://#{image_path}")
                yield(image_location, image_path)
              end
            end
          end
        end
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength
    end
  end
end
