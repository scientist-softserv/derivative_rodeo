# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DerivativeRodeo::Services::ExtractWordCoordinatesFromHocrSgmlService do
  let(:minimal) { File.read(minimal_path) }

  let(:reader_minimal) { described_class.new(minimal) }
  let(:reader_minimal_path) { described_class.new(minimal_path) }

  let(:xml) { File.read(Fixtures.path_for('ocr_mono_text_hocr.html')) }
  let(:hocr) { described_class.new(xml) }
  subject { hocr }

  # I want to deprecate this, but for now, it's here.
  it { is_expected.to respond_to(:json) }

  describe '#text' do
    let(:xml) { File.read(Fixtures.path_for('ocr_mono_text_hocr.html')) }
    subject { hocr.text }

    it 'outputs plain text' do
      expect(subject.slice(0, 40)).to eq "_A FEARFUL ADVENTURE.\n‘The Missouri. Rep"
      expect(subject.size).to eq 723
    end
  end

  describe '#to_json' do
    subject { hocr.to_json }
    it 'outputs JSON that includes coords key with unique coordinate values' do
      parsed = JSON.parse(subject)
      expect(parsed['coords'].length).to be > 1
      parsed['coords'].values.each do |value|
        expect(value.uniq.length).to eq(value.length)
      end
    end
  end
end
