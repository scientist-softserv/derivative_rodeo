# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DerivativeRodeo::Generators::CopyGenerator do
  let(:kwargs) { { input_uris: [] } }
  let(:result_path) { nil }
  subject { described_class.new(**kwargs) }

  %i[input_uris output_adapter_name output_extension generated_files].each do |method|
    it "responds to #{method}" do
      expect(subject).to respond_to(method)
    end

    it "responds to #{method}=" do
      expect(subject).to respond_to("#{method}=")
    end
  end

  before do
    FileUtils.rm_f(result_path) if result_path
  end

  after do
    FileUtils.rm_f(result_path) if result_path
  end

  describe '#generated_files' do
    let(:kwargs) { { input_uris: [file_uri] } }
    let(:file_path) { File.join(FIXTURE_PATH, 'files', 'ocr_color.tiff') }
    let(:file_uri) { "file://#{file_path}" }

    xit 'copies the given files to the target location' do
      expect { subject.generated_files }.not_to raise_error
    end
  end
end
