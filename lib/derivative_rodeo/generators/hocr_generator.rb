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

      self.output_extension = 'hocr'

      # @!attribute [rw]
      # The tesseract command's output base; default `:hocr`.
      class_attribute :output_suffix, default: :hocr
      # @!endgroup Class Attributes

      ##
      # Run tesseract on monocrhome file and store the resulting output in the configured
      # {.output_extension} (default 'hocr')
      #
      # @param in_file [StorageAdapters::BaseAdapter] the results of
      #        {MonochromeGenerator#generate_files}
      # @param out_file [StorageAdapters::BaseAdapter]
      #
      # @return [StorageAdapters::BaseAdapter]
      #
      # @see #requisite_files
      def build_step(in_file:, out_file:)
        @result = nil
        in_file.with_existing_tmp_path do |tmp_path|
          @result = tesseractify(tmp_path, out_file)
        end
        @result
      end

      ##
      # @param builder [Class, #generate_files]
      # @return [Array<StorageAdapters::BaseAdapter>] file_uris of the monochrome derivatives
      def requisite_files(builder: MonochromeGenerator)
        @requisite_files ||= builder.new(input_uris: input_uris).generated_files
      end

      ##
      # @api private
      #
      # Call `tesseract` on the monochrome file and store the resulting hocr
      # in the tmp_path
      #
      # @param tmp_path [String].
      # @param out_file [StorageAdapters::BaseAdapter]
      def tesseractify(tmp_path, out_file)
        out_file.with_new_tmp_path do |out_path|
          run_tesseract(tmp_path, out_path)
        end
        out_file
      end

      ##
      # @param tmp_path [String] the source of the file
      # @param out_path [String]
      def run_tesseract(tmp_path, out_path)
        # we pull the extension off the output path, because tesseract will add it back
        cmd = ""
        cmd += command_environment_variables + " " if command_environment_variables.present?
        # TODO: The line of code could mean we had a file with multiple periods and we'd just
        # replace the first one.  Should we instead prefer the following:
        #
        # `out_path.split(".")[0..-2].join('.') + ".#{output_extension}"`
        output_to_path = out_path.sub('.' + output_extension, '')
        cmd += "tesseract #{tmp_path} #{output_to_path}"
        cmd += " #{additional_tessearct_options}" if additional_tessearct_options.present?
        cmd += " #{output_suffix}"

        # TODO: capture output in case of exceptions; perhaps delegate that to the #run method.
        run(cmd)
      end
    end
  end
end
