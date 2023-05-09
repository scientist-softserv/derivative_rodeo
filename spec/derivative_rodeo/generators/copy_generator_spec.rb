# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DerivativeRodeo::Generators::CopyGenerator do
  let(:kwargs) { { input_uris: [], output_target_template: nil } }
  subject(:instance) { described_class.new(**kwargs) }

  %i[input_uris output_extension output_extension= generated_files].each do |method|
    it { is_expected.to respond_to(method) }
  end

  it { is_expected.to be_a(DerivativeRodeo::Generators::CopyFileConcern) }
  its(:output_extension) { is_expected.to eq(DerivativeRodeo::StorageAdapters::SAME) }

  describe '#generated_files' do
    let(:kwargs) { { input_uris: [file_uri] } }
    let(:file_path) { File.join(FIXTURE_PATH, 'files', 'ocr_color.tiff') }
    let(:file_uri) { "file://#{file_path}" }

    it 'copies the given files to the target location' do
      generated_files = nil
      Fixtures.with_temporary_directory do |output_temporary_path|
        output_target_template = "file://#{output_temporary_path}/{{dir_parts[-1..-1]}}/{{ filename }}"
        instance = described_class.new(input_uris: [file_uri], output_target_template: output_target_template)
        generated_files = instance.generated_files
        expect(generated_files.all?(&:exist?)).to be_truthy
      end
      # Assert that we're doing clean-up; all of those generated files were destroyed once we exited
      # the scope of the Fixtures.with_temporary_directory block.
      expect(generated_files.all?(&:exist?)).to be_falsey
    end
  end
end
