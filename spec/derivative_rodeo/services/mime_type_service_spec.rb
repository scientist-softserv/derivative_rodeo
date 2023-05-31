# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DerivativeRodeo::Services::MimeTypeService do
  describe '.mime_type' do
    subject { described_class.mime_type(filename: filename) }
    {
      __FILE__ => "text/x-ruby",
      Fixtures.path_for('4.1.07.tiff') => "image/tiff",
      Fixtures.path_for('tiff-no-ext') => "image/tiff",
      Fixtures.path_for('minimal-1-page.pdf') => "application/pdf",
      Fixtures.path_for('ndnp-sample1-txt.txt') => "text/plain"
    }.each do |given_filename, expected_mime_type|
      context "for #{File.basename(given_filename)}" do
        let(:filename) { given_filename }
        it { is_expected.to eq(expected_mime_type) }
      end
    end
  end

  describe '.hyrax_type' do
    subject { described_class.hyrax_type(filename: filename) }
    {
      Fixtures.path_for('4.1.07.tiff') => :image,
      Fixtures.path_for('minimal-1-page.pdf') => :pdf,
      Fixtures.path_for('ndnp-sample1-txt.txt') => :text
    }.each do |given_filename, expected_hyrax_type|
      context "for #{File.basename(given_filename)}" do
        let(:filename) { given_filename }
        it { is_expected.to eq(expected_hyrax_type) }
      end
    end
  end
end
