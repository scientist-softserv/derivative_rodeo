# frozen_string_literal: true

module DerivativeRodeo
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
  module Generators
    ##
    # Take images and creates an horc file from them
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

      ##
      # @!attribute [rw]
      # file tld for output, default `:hocr`.
      class_attribute :output_extension, default: 'hocr'

      # @!attribute [rw]
      # The tesseract command's output base; default `:hocr`.
      class_attribute :output_suffix, default: :hocr
      # @!endgroup

      ##
      # in_file here should be a monochrome file due to preprocess
      # will run tesseract on the file and store the resulting hocr
      def build_step(in_file:, out_file:)
        @result = nil
        in_file.with_existing_tmp_path do |tmp_path|
          @result = tesseractify(tmp_path, out_file)
        end
        @result
      end

      ##
      #  @return [Array<String>] file_uris of the monochrome derivatives
      def requisite_files
        @requisite_files ||= MonochromeGenerator.new(input_uris: input_uris).generated_files
      end

      ##
      # call tesseract on the monochrome file and store the resulting hocr
      # in the tmp_path
      def tesseractify(tmp_path, out_file)
        out_file.with_new_tmp_path do |out_path|
          run_tesseract(tmp_path, out_path)
          # TODO: do we always write? is it always last?
          out_file.write
        end
        out_file
      end

      def run_tesseract(tmp_path, out_path)
        # we pull the extension off the output path, because tesseract will add it back
        cmd = ""
        cmd += command_environment_variables + " " if command_environment_variables.present?
        cmd += "tesseract #{tmp_path} #{out_path.sub('.' + output_extension, '')}"
        cmd += " #{additional_tessearct_options}" if additional_tessearct_options.present?
        cmd += " #{output_suffix}"

        # TODO: capture output in case of exceptions
        run(cmd)
      end
    end
  end
end
