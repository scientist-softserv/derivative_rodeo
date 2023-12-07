# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DerivativeRodeo::Services::ConvertUriViaTemplateService do
  describe '.separator' do
    subject { described_class.separator }
    it { is_expected.to eq('/') }
  end
  describe '.call' do
    subject { described_class.call(**kwargs) }
    [
      { from_uri: "file:///path1/A/file.pdf",
        template: "file:///dest1/{{dir_parts[-1..-1]}}/{{filename}}",
        adapter: DerivativeRodeo::StorageLocations::FileLocation,
        expected: "file:///dest1/A/file.pdf" },
      { from_uri: "aws:///path1/A/file1.pdf",
        template: "{{ scheme }}:///dest1/{{dir_parts[-1..-1]}}/{{filename}}",
        adapter: DerivativeRodeo::StorageLocations::FileLocation,
        expected: "file:///dest1/A/file1.pdf" },
      { from_uri: "file:///path1/A/file1.pdf",
        template: "file:///dest1/{{dir_parts[-1..-1]}}/{{basename}}/derived{{extension}}",
        adapter: DerivativeRodeo::StorageLocations::FileLocation,
        expected: "file:///dest1/A/file1/derived.pdf" },
      { from_uri: "file:///path1/A/file1.pdf",
        template: "file:///dest1/{{dir_parts[-1..-1]}}/{{basename}}/derived{{extension}}",
        extension: "hello",
        adapter: DerivativeRodeo::StorageLocations::FileLocation,
        expected: "file:///dest1/A/file1/derived.hello" },
      { from_uri: "file:///path1/A/file1.pdf",
        template: "file:///dest1/{{dir_parts[-1..-1]}}/{{basename}}/derived{{extension}}",
        extension: DerivativeRodeo::StorageLocations::SAME,
        adapter: DerivativeRodeo::StorageLocations::FileLocation,
        expected: "file:///dest1/A/file1/derived.pdf" },
      { from_uri: "file:///path1/A/file1.mono.tiff",
        template: "file:///dest1/{{dir_parts[-1..-1]}}/{{basename}}/file1{{extension}}",
        extension: 'hocr',
        adapter: DerivativeRodeo::StorageLocations::FileLocation,
        expected: "file:///dest1/A/file1/file1.hocr" }
    ].each do |hash|
      context "with #{hash.except(:expected)}" do
        let(:kwargs) { hash.except(:expected) }

        it { is_expected.to eq(hash.fetch(:expected)) }
      end
    end
  end

  describe '.coerce_pre_requisite_template_from' do
    subject { described_class.coerce_pre_requisite_template_from(template: template) }
    [
      ["file://path/one/text.png", "file://path/one/{{ basename }}{{ extension }}"]
    ].each do |given_template, expected_template|
      context "given #{given_template.inspect}" do
        let(:template) { given_template }
        it { is_expected.to eq expected_template }
      end
    end
  end
end
