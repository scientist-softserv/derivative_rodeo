# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DerivativeRodeo::Generators::CopyGenerator do
  let(:kwargs) { { input_uris: [] } }
  let(:result_path) { nil }
  around do |spec|
    FileUtils.rm_f(result_path) if result_path
    spec.run
    FileUtils.rm_f(result_path) if result_path
  end
  subject { described_class.new(**kwargs) }

  %i[input_uris output_adapter_name output_extension generated_files].each do |method|
    it { is_expected.to respond_to(method) }
    it { is_expected.to respond_to("#{method}=") }
  end

  it { is_expected.to be_a(DerivativeRodeo::Generators::CopyFileConcern) }
  its(:output_extension) { is_expected.to eq(DerivativeRodeo::StorageAdapters::SAME) }

  describe '#generated_files' do
    let(:kwargs) { { input_uris: [file_uri] } }
    let(:file_path) { File.join(FIXTURE_PATH, 'files', 'ocr_color.tiff') }
    let(:file_uri) { "file://#{file_path}" }

    it 'copies the given files to the target location' do
      expect { subject.generated_files }.not_to raise_error
    end
  end
end
