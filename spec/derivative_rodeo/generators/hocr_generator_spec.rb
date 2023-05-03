# frozen_string_literal: true

RSpec.describe DerivativeRodeo::Generators::HocrGenerator do
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

  context 'with color image' do
    let(:file_path) { File.join(FIXTURE_PATH, 'files', 'ocr_color.tiff') }
    let(:result_path) do
      File.join(FIXTURE_PATH, 'files', 'ocr_color.hocr')
    end
    let(:file_uri) { "file://#{file_path}" }
    let(:kwargs) { { input_uris: [file_uri] } }

    it 'builds a hocr file' do
      expect { subject.generated_files }.not_to raise_error
      expect(File.exist?(result_path)).to be true
      expect(File.foreach(result_path).grep(/brigade/).any?).to be true
    end
  end

  context 'with pre processed color image' do
    let(:file_path) { File.join(FIXTURE_PATH, 'files', 'ocr_color_pre.tiff') }
    let(:result_path) do
      File.join(FIXTURE_PATH, 'files', 'ocr_color_pre.hocr')
    end
    let(:file_uri) { "file://#{file_path}" }
    let(:kwargs) { { input_uris: [file_uri] } }

    it 'builds a hocr file' do
      expect { subject.generated_files }.not_to raise_error
      expect(File.exist?(result_path)).to be true
      expect(File.foreach(result_path).grep(/brigade/).any?).to be true
    end
  end

  context 'with an already mono file' do
    let(:file_path) { File.join(FIXTURE_PATH, 'files', 'ocr_mono.tiff') }
    let(:result_path) do
      File.join(FIXTURE_PATH, 'files', 'ocr_mono.hocr')
    end
    let(:file_uri) { "file://#{file_path}" }
    let(:kwargs) { { input_uris: [file_uri] } }

    it 'builds a hocr file' do
      # do not delete result path, the file should stay put
      expect { subject.generated_files }.not_to raise_error
      expect(File.exist?(result_path)).to be true
      expect(File.foreach(result_path).grep(/occasioned/).any?).to be true
    end
  end
end
