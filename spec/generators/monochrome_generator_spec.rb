# frozen_string_literal: true

RSpec.describe DerivativeZoo::Generator::MonochromeGenerator do
  let(:args) { { input_uris: [] } }
  subject { described_class.new(args) }

  %i[input_uris output_adapter_name output_extension generated_files].each do |method|
    it "responds to #{method}" do
      expect(subject).to respond_to(method)
    end

    it "responds to #{method}=" do
      expect(subject).to respond_to("#{method}=")
    end
  end

  context 'with color image' do
    let(:file_path) { File.join(FIXTURE_PATH, 'files', 'ocr_color.tiff') }
    let(:result_path) do
      File.join(FIXTURE_PATH, 'files', 'ocr_color.mono.tiff')
    end
    let(:file_uri) { "file://#{file_path}" }
    let(:args) { { input_uris: [file_path] } }

    it 'builds a monochrome image' do
      FileUtils.rm_f(result_path)
      file = DerivativeZoo::StorageAdapter::FileAdapter.new(file_uri)
      expect { subject.build_step(file) }.not_to raise_error
      expect(File.exist?(result_path)).to be true
    end

    after do
      FileUtils.rm_f(result_path)
    end
  end

  context 'with monochrome image' do
    let(:file_path) { File.join(FIXTURE_PATH, 'files', 'ocr_mono.tiff') }
    let(:result_path) do
      File.join(FIXTURE_PATH, 'files', 'ocr_mono.tiff')
    end
    let(:file_uri) { "file://#{file_path}" }
    let(:args) { { input_uris: [file_path] } }

    it 'builds a monochrome image' do
      # do not delete result path, the file should stay put
      file = DerivativeZoo::StorageAdapter::FileAdapter.new(file_uri)
      expect { subject.build_step(file) }.not_to raise_error
      expect(File.exist?(result_path)).to be true
      expect(File.exist?(result_path.sub('.tiff', '.mono.tiff'))).to be_falsey
    end
  end
end
