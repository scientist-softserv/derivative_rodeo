# frozen_string_literal: true

RSpec.describe DerivativeRedeo::Generator::MonochromeGenerator do
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
    let(:args) { { input_uris: [file_uri] } }

    it 'builds a monochrome image' do
      FileUtils.rm_f(result_path)
      expect { subject.generated_files }.not_to raise_error
      expect(File.exist?(result_path)).to be true
    end

    after do
      FileUtils.rm_f(result_path)
    end
  end

  context 'with pre processed color image' do
    let(:file_path) { File.join(FIXTURE_PATH, 'files', 'ocr_color_pre.tiff') }
    let(:result_path) do
      File.join(FIXTURE_PATH, 'files', 'ocr_color_pre.mono.tiff')
    end
    let(:file_uri) { "file://#{file_path}" }
    let(:args) { { input_uris: [file_uri] } }

    it 'builds a monochrome image' do
      expect { subject.generated_files }.not_to raise_error
      expect(File.exist?(result_path)).to be true
    end
  end

  context 'with monochrome image' do
    let(:file_path) { File.join(FIXTURE_PATH, 'files', 'ocr_mono.tiff') }
    let(:result_path) do
      File.join(FIXTURE_PATH, 'files', 'ocr_mono.tiff')
    end
    let(:file_uri) { "file://#{file_path}" }
    let(:args) { { input_uris: [file_uri] } }

    it 'builds a monochrome image' do
      # do not delete result path, the file should stay put
      expect { subject.generated_files }.not_to raise_error
      expect(File.exist?(result_path)).to be true
      expect(File.exist?(result_path.sub('.tiff', '.mono.tiff'))).to be_falsey
    end
  end
end
