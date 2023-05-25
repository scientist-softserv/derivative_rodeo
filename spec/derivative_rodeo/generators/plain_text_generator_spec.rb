# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DerivativeRodeo::Generators::PlainTextGenerator do
  describe "#generated_files" do
    it "derives the plain text from the given hocr file" do
      generated_file = nil
      Fixtures.with_file_uris_for("ocr_mono_text_hocr.html") do |hocr_uris, from_tmp_dir|
        template = "file://#{from_tmp_dir}/{{ basename }}.plain_text.txt"
        instance = described_class.new(input_uris: hocr_uris, output_location_template: template)
        generated_file = instance.generated_files.first
        text = File.read(generated_file.file_path)
        expect(generated_file.exist?).to be_truthy
        expect(generated_file.file_path).to end_with("/ocr_mono_text_hocr.plain_text.txt")
        expect(text.lines.size).to eq 19
        expect(text.lines.first).to eq "_A FEARFUL ADVENTURE.\n"
      end

      expect(generated_file.exist?).to be_falsey
    end
  end
end
