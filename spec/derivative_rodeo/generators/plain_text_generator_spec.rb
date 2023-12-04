# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DerivativeRodeo::Generators::PlainTextGenerator do
  it "has the correct output_extension" do
    expect(described_class.output_extension).to eq "plain_text.txt"
  end

  it "has the correct service class" do
    expect(described_class.service).to eq DerivativeRodeo::Services::ExtractWordCoordinatesFromHocrSgmlService
  end

  describe "#generated_files" do
    it "derives the plain text from the given hocr file" do
      generated_file = nil
      Fixtures.with_file_uris_for("ocr_mono.tiff") do |uris, from_tmp_dir|
        template = "file://#{from_tmp_dir}/{{ basename }}.plain_text.txt"
        instance = described_class.new(input_uris: uris, output_location_template: template)
        generated_file = instance.generated_files.first
        text = File.read(generated_file.file_path)
        expect(generated_file.exist?).to be_truthy
        expect(generated_file.file_path).to end_with("/ocr_mono.plain_text.txt")
        expect(text.lines.size).to be_a(Integer)
        expect(text.lines.first).to eq "_A FEARFUL ADVENTURE.\n"
      end

      expect(generated_file.exist?).to be_falsey
    end
  end
end
