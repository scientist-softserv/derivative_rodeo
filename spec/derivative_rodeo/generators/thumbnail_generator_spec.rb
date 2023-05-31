# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DerivativeRodeo::Generators::ThumbnailGenerator do
  context '.output_extension' do
    subject { described_class.output_extension }
    it { is_expected.to eq("thumbnail.jpeg") }
  end

  context '.dimensions_by_type' do
    subject { described_class.dimensions_by_type }
    it { is_expected.to be_a(Hash) }
  end

  context '.dimensions_fallback' do
    subject { described_class.dimensions_fallback }
    it { is_expected.to eq("200x150>") }
    it { is_expected.to be_a String }
  end

  describe '.dimensions_for' do
    subject { described_class.dimensions_for(filename: filename) }

    context "given a file ending in '.pdf'" do
      let(:filename) { "really-cool.pdf" }
      it { is_expected.to eq described_class.dimensions_by_type.fetch(:pdf) }
    end

    context "given a file without an extension" do
      let(:filename) { "aint-no-extension-here" }
      it { is_expected.to eq described_class.dimensions_fallback }
    end

    context "given a file ending in '.tiff'" do
      let(:filename) { "muppet-man.tiff" }
      it { is_expected.to eq described_class.dimensions_fallback }
    end
  end

  describe "#generated_files" do
    context 'for a PDF' do
      it 'creates a thumbnail.jpeg file' do
        generated_file = nil
        Fixtures.with_file_uris_for("minimal-2-page.pdf") do |pdf_uris, from_tmp_dir|
          template = "file://#{from_tmp_dir}/{{ basename }}.thumbnail.jpeg"
          instance = described_class.new(input_uris: pdf_uris, output_location_template: template)
          generated_file = instance.generated_files.first

          # generated_file.file_path is where the thumbnail will be within the Fixtures block; once
          # the block closes, that thumbnail is cleaned up.
          expect(generated_file.exist?).to be_truthy
          expect(generated_file.file_path).to end_with("/minimal-2-page.thumbnail.jpeg")
        end

        expect(generated_file.exist?).to be_falsey
      end
    end

    context 'for an Image' do
      it 'creates a thumbnail.jpeg file' do
        generated_file = nil
        Fixtures.with_file_uris_for("4.1.07.tiff") do |tiff_uris, from_tmp_dir|
          template = "file://#{from_tmp_dir}/{{ basename }}.thumbnail.jpeg"
          instance = described_class.new(input_uris: tiff_uris, output_location_template: template)
          generated_file = instance.generated_files.first

          # generated_file.file_path is where the thumbnail will be within the Fixtures block; once
          # the block closes, that thumbnail is cleaned up.
          expect(generated_file.exist?).to be_truthy
          expect(generated_file.file_path).to end_with("/4.1.07.thumbnail.jpeg")
        end

        expect(generated_file.exist?).to be_falsey
      end
    end
  end
end
