# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DerivativeRodeo::Services::ConvertUrisWithUriTemplateService do
  describe '.call' do
    subject { described_class.call(**kwargs) }
    [
      { from_uris: ["file:///path1/A/file.pdf", "file:///path2/B/file.pdf"],
        template: "file:///dest1/{{dir_parts[-1..-1]}}/{{filename}}",
        expected: ["file:///dest1/A/file.pdf", "file:///dest1/B/file.pdf"] },
      { from_uris: ["file:///path1/A/file1.pdf", "aws:///path2/B/file2.pdf"],
        template: "file:///dest1/{{dir_parts[-1..-1]}}/{{filename}}",
        expected: ["file:///dest1/A/file1.pdf", "file:///dest1/B/file2.pdf"] },
      { from_uris: ["file:///path1/A/file1.pdf", "aws:///path2/B/file2.pdf"],
        template: "file:///dest1/{{dir_parts[-1..-1]}}/{{basename}}/derived{{extension}}",
        expected: ["file:///dest1/A/file1/derived.pdf", "file:///dest1/B/file2/derived.pdf"] },
    ].each do |hash|
      context "with from_uris: #{hash.fetch(:from_uris)} and template: #{hash.fetch(:template)}" do
        let(:kwargs) { hash.slice(:from_uris, :template) }

        it { is_expected.to eq(hash.fetch(:expected)) }
      end
    end
  end
end
