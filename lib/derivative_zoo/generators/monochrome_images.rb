# frozen_string_literal: true

module DerivativeZoo
  ##
  # Generators execute a transofrmatoin on files and return new files
  # A generator class must set an output extention and must implment
  # a build_step method
  module Generator
    ##
    # Take images an insure we have a monochrome derivative of them
    class MonochromeImages < BaseGenerator
      self.output_extension = 'mono.tif'

      def input_files
        @input_files ||= input_uris.map do |file_uri|
          DerivativeZoo::StorageAdapter::Base.from_uri(file_uri)
        end
      end

      def build_step(file)
        file.with_tmp_path do |_tmo_path|
          # TODO: move this
          image = Derivative::Rodeo::Utilities::Image.new(tmp_path)
          if image.monochrome?
            file
          else
            monochromify(file, image)
          end
        end
      end
    end

    def monochromify(file, image)
      monochrome_file = file.derived_file(extension: output_extension,
                                          adapter_name: output_adapter_name)
      # Convert the above image to a file at the monochrome_path
      monochrome_file.with_tmp_path do |monochrome_path|
        image.convert(monochrome_path, true)
        monochrome_file.write
      end
      monochrome_file
    end
  end
end
