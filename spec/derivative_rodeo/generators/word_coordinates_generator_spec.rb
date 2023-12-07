# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DerivativeRodeo::Generators::WordCoordinatesGenerator do
  describe "#generated_files" do
    it "derives the word coordinates from the given hocr file" do
      generated_file = nil
      Fixtures.with_file_uris_for("ocr_mono.tiff") do |uris, from_tmp_dir|
        mono_uri = uris.first
        template = "file://#{from_tmp_dir}/{{ basename }}{{ extension }}"
        instance = described_class.new(input_uris: [mono_uri], output_location_template: template)

        generated_file = instance.generated_files.first
        json = JSON.parse(File.read(generated_file.file_path))
        expect(json.keys).to match_array(["width", "height", "coords"])
        expect(generated_file.exist?).to be_truthy
        expect(generated_file.file_path).to end_with("/ocr_mono.coordinates.json")
      end

      expect(generated_file.exist?).to be_falsey
    end
  end
end
