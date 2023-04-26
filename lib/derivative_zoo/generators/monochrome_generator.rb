# frozen_string_literal: true

module DerivativeZoo
  ##
  # Generators execute a transofrmatoin on files and return new files
  # A generator class must set an output extention and must implment
  # a build_step method
  module Generator
    ##
    # Take images an insure we have a monochrome derivative of them
    class MonochromeGenerator < BaseGenerator
      self.output_extension = 'mono.tiff'

      def input_files
        @input_files ||= input_uris.map do |file_uri|
          DerivativeZoo::StorageAdapter::Base.from_uri(file_uri)
        end
      end

      def build_step(file)
        monochrome_file = monochrome_file(file)
        return monochrome_file if monochrome_file.exists?

        file.with_existing_tmp_path do |tmp_path|
          image = DerivativeZoo::Service::ImageService.new(tmp_path)
          if image.monochrome?
            file
          else
            monochromify(monochrome_file, image)
          end
        end
      end

      def monochrome_file(file)
        file.derived_file(extension: output_extension,
                          adapter_name: output_adapter_name)
      end

      def monochromify(monochrome_file, image)
        # Convert the above image to a file at the monochrome_path
        monochrome_file.with_new_tmp_path do |monochrome_path|
          image.convert(destination: monochrome_path, monochrome: true)
          monochrome_file.write
        end
        monochrome_file
      end
    end
  end
end
