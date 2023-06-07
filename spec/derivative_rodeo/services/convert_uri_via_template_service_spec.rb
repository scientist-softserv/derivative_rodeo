# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DerivativeRodeo::Services::ConvertUriViaTemplateService do
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
        expected: "file:///dest1/A/file1/derived.pdf" }
    ].each do |hash|
      context "with #{hash.except(:expected)}" do
        let(:kwargs) { hash.except(:expected) }

        it { is_expected.to eq(hash.fetch(:expected)) }
      end
    end
  end
end
