# frozen_string_literal: true

require 'spec_helper'
require 'nokogiri'

RSpec.describe DerivativeRodeo::Generators::AltoGenerator do
  it "has the correct output_extension" do
    expect(described_class.output_extension).to eq "alto.xml"
  end

  it "has the correct service class" do
    expect(described_class.service).to eq DerivativeRodeo::Services::ExtractWordCoordinatesFromHocrSgmlService
  end

  describe "#generated_files" do
    it "derives a valid alto xml from the given hocr file" do
      generated_file = nil
      Fixtures.with_file_uris_for("ocr_mono_text_hocr.html") do |hocr_uris, from_tmp_dir|
        template = "file://#{from_tmp_dir}/{{ basename }}.alto.xml"
        instance = described_class.new(input_uris: hocr_uris, output_location_template: template)
        generated_file = instance.generated_files.first
        expect(generated_file.exist?).to be_truthy
        expect(generated_file.file_path).to end_with("/ocr_mono_text_hocr.alto.xml")

        # Check that the XML is well-formed
        doc = nil
        expect do
          File.open(generated_file.file_path, "r") do |file|
            doc = Nokogiri::XML(file) { |config| config.strict.nonet }
          end
        end.not_to raise_error
        expect(doc.errors).to be_empty
      end

      expect(generated_file.exist?).to be_falsey
    end
  end
end
