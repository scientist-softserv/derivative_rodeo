# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DerivativeRodeo::StorageLocations::HttpsLocation do
  let(:input_uri) { "https://hello.com/path/to/source.txt" }
  subject(:instance) { described_class.new(input_uri) }

  context '#matching_locations_in_file_dir' do
    subject { instance.matching_locations_in_file_dir(tail_regexp: %r{.*}) }

    it { is_expected.to be_empty }

    it 'logs info explaining the reason for always being empty' do
      expect(instance.logger).to receive(:info).with(String)

      subject
    end
  end
end
