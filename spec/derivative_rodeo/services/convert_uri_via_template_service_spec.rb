# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DerivativeRodeo::Services::ConvertUriViaTemplateService do
  describe '.call' do
    subject { described_class.call(**kwargs) }
    [
      { from_uri: "file:///path1/A/file.pdf",
        template: "file:///dest1/{{dir_parts[-1..-1]}}/{{filename}}",
        expected: "file:///dest1/A/file.pdf" },
      { from_uri: "aws:///path1/A/file1.pdf",
        template: "file:///dest1/{{dir_parts[-1..-1]}}/{{filename}}",
        expected: "file:///dest1/A/file1.pdf" },
      { from_uri: "file:///path1/A/file1.pdf",
        template: "file:///dest1/{{dir_parts[-1..-1]}}/{{basename}}/derived{{extension}}",
        expected: "file:///dest1/A/file1/derived.pdf" }
    ].each do |hash|
      context "with from_uri: #{hash.fetch(:from_uri)} and template: #{hash.fetch(:template)}" do
        let(:kwargs) { hash.slice(:from_uri, :template) }

        it { is_expected.to eq(hash.fetch(:expected)) }
      end
    end
  end
end
