# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DerivativeRodeo::Generators::WordCoordinatesGenerator do
  describe "#generated_files" do
    it "derives the word coordinates from the given hocr file" do
      generated_file = nil
      Fixtures.with_file_uris_for("ocr_mono_text_hocr.html") do |hocr_uris, from_tmp_dir|
        template = "file://#{from_tmp_dir}/{{ basename }}.coordinates.json"
        instance = described_class.new(input_uris: hocr_uris, output_location_template: template)
        generated_file = instance.generated_files.first
        json = JSON.parse(File.read(generated_file.file_path))
        expect(json.keys).to match_array(["width", "height", "coords"])
        expect(generated_file.exist?).to be_truthy
        expect(generated_file.file_path).to end_with("/ocr_mono_text_hocr.coordinates.json")
      end

      expect(generated_file.exist?).to be_falsey
    end
  end
end
