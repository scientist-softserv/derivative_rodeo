# frozen_string_literal: true

module DerivativeRodeo
  module Generators
    ##
    # Responsible for finding or creating a hocr file (or configured :output_suffix) using
    # tesseract. Will create and store a monochrome derivative if one is not found.
    #
    # @see http://tesseract-ocr.github.io
    #
    # From `tesseract -h`
    #
    #   Usage:
    #     tesseract --help | --help-extra | --version
    #     tesseract --list-langs
    #     tesseract imagename outputbase [options...] [configfile...]
    class HocrGenerator < BaseGenerator
      ##
      # @!group Class Attributes
      # @!attribute [rw]
      # Command arena variables to for tesseract command; default `nil`.
      # Should be a space seperated string of KEY=value pairs
      #
      # @example
      #   # this works for space_stone aws lambda
      #   Derivative::Rodeo::Step::HocrStep.command_environment_variables =
      #     'OMP_THREAD_LIMIT=1 TESSDATA_PREFIX=/opt/share/tessdata LD_LIBRARY_PATH=/opt/lib PATH=/opt/bin:$PATH'
      class_attribute :command_environment_variables, default: "OMP_THREAD_LIMIT=1"

      ##
      # @!attribute [rw]
      # Additional options to send to tesseract command; default `nil`.
      class_attribute :additional_tessearct_options, default: nil

      # @!attribute [rw]
      # The tesseract command's output base; default `:hocr`.
      class_attribute :output_suffix, default: :hocr

      self.output_extension = 'hocr'
      # @!endgroup Class Attributes

      ##
      # Run tesseract on monocrhome file and store the resulting output in the configured
      # {.output_extension} (default 'hocr')
      #
      # @param output_location [StorageLocations::BaseLocation]
      # @param input_tmp_file_path [String]
      #
      # @return [StorageLocations::BaseLocation]
      #
      # @see #requisite_files
      def build_step(output_location:, input_tmp_file_path:, **)
        tesseractify(input_tmp_file_path, output_location)
      end

      ##
      # @param builder [Class, #generated_files]
      #
      # When generating a hocr file from an image, we've found the best results are when we're
      # processing a monochrome image.  As such, this generator will auto-convert a given image to
      # monochrome.
      #
      # @yieldparam file [StorageLocations::BaseLocation]
      # @yieldparam tmp_path [String]
      #
      # @see BaseGenerator#with_each_requisite_location_and_tmp_file_path for further discussion
      def with_each_requisite_location_and_tmp_file_path(builder: MonochromeGenerator)
        mono_location_template = Services::ConvertUriViaTemplateService.coerce_pre_requisite_template_from(template: output_location_template)

        requisite_files ||= builder.new(input_uris: input_uris, output_location_template: mono_location_template).generated_files
        requisite_files.each do |input_location|
          input_location.with_existing_tmp_path do |tmp_file_path|
            yield(input_location, tmp_file_path)
          end
        end
      end

      ##
      # @api private
      #
      # Call `tesseract` on the monochrome file and store the resulting hocr
      # in the tmp_path
      #
      # @param input_tmp_file_path [String].
      # @param output_location [StorageLocations::BaseLocation]
      def tesseractify(input_tmp_file_path, output_location)
        output_location.with_new_tmp_path do |out_tmp_path|
          run_tesseract(input_tmp_file_path, out_tmp_path)
        end
      end

      ##
      # @param in_path [String] the source of the file
      # @param out_path [String]
      def run_tesseract(in_path, out_path)
        # we pull the extension off the output path, because tesseract will add it back
        cmd = ""
        cmd += command_environment_variables + " " if command_environment_variables.present?
        # TODO: The line of code could mean we had a file with multiple periods and we'd just
        # replace the first one.  Should we instead prefer the following:
        #
        # `out_path.split(".")[0..-2].join('.') + ".#{output_extension}"`
        output_to_path = out_path.sub('.' + output_extension, '')
        cmd += "tesseract #{in_path} #{output_to_path}"
        cmd += " #{additional_tessearct_options}" if additional_tessearct_options.present?
        cmd += " #{output_suffix}"

        # TODO: capture output in case of exceptions; perhaps delegate that to the #run method.
        run(cmd)
      end

      ##
      # A mixin for generators that rely on hocr files.
      #
      # @see #with_each_requisite_location_and_tmp_file_path
      module RequiresExistingFile
        ##
        # @param builder [Class, #generated_files]
        #
        # When a generator depends on a hocr file, this method will ensure that we have the requisite
        # hocr file.
        #
        # @yieldparam file [StorageLocations::BaseLocation]
        # @yieldparam tmp_path [String]
        #
        # @see BaseGenerator#with_each_requisite_location_and_tmp_file_path for further discussion
        def with_each_requisite_location_and_tmp_file_path(builder: HocrGenerator)
          prereq_output_location_template = Services::ConvertUriViaTemplateService.coerce_pre_requisite_template_from(template: output_location_template)
          requisite_files ||= builder.new(input_uris: input_uris, output_location_template: prereq_output_location_template).generated_files
          requisite_files.each do |input_location|
            input_location.with_existing_tmp_path do |tmp_file_path|
              yield(input_location, tmp_file_path)
            end
          end
        end
      end
    end
  end
end
