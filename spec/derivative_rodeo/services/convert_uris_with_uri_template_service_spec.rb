# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DerivativeRodeo::Services::ConvertUrisWithUriTemplateService do
  describe '.call' do
    subject { described_class.call(**kwargs) }
    [
      { from_uris: ["file:///path1/A/file.pdf", "file:///path2/B/file.pdf"],
        template: "file:///dest1/{{path_parts[-2..-1]}}",
        expected: ["file:///dest1/A/file.pdf", "file:///dest1/B/file.pdf"] },
      { from_uris: ["aws:///path1/A/file.pdf", "aws:///path2/B/file.pdf"],
        template: "{{ from_scheme }}/dest1/{{path_parts[-2..-1]}}",
        expected: ["aws:///dest1/A/file.pdf", "aws:///dest1/B/file.pdf"] },
      { from_uris: ["aws:///path1/A/file.pdf", "file:///path2/B/file.pdf"],
        template: "{{from_scheme}}/dest1/{{  path_parts[-2..-1]  }}",
        expected: ["aws:///dest1/A/file.pdf", "file:///dest1/B/file.pdf"] }
    ].each do |hash|
      context "with from_uris: #{hash.fetch(:from_uris)} and template: #{hash.fetch(:template)}" do
        let(:kwargs) { hash.slice(:from_uris, :template) }

        it { is_expected.to eq(hash.fetch(:expected)) }
      end
    end
  end
end
