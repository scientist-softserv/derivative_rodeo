# frozen_string_literal: true

RSpec.describe DerivativeRodeo::Generators::MonochromeGenerator do
  let(:kwargs) { { input_uris: [] } }
  subject(:instance) { described_class.new(**kwargs) }

  %i[input_uris output_adapter_name output_extension generated_files].each do |method|
    it { is_expected.to respond_to method }
    it { is_expected.to respond_to "#{method}=" }
  end

  its(:output_extension) { is_expected.to eq('mono.tiff') }

  describe '#generated_files' do
    let(:file_uri) { "file://#{file_path}" }
    let(:kwargs) { { input_uris: [file_uri] } }
    subject(:generated_files) { instance.generated_files }

    context 'with color image' do
      let(:file_path) { File.join(FIXTURE_PATH, 'files', 'ocr_color.tiff') }
      let(:result_path) { File.join(FIXTURE_PATH, 'files', 'ocr_color.mono.tiff') }

      it 'builds a monochrome image' do
        FileUtils.rm_f(result_path)
        expect { generated_files }.not_to raise_error
        expect(File.exist?(result_path)).to be true
      end

      # TODO: How can we more regularly clean things up?  Do we need some kind of test file adapter?
      after { FileUtils.rm_f(result_path) }
    end

    context 'with pre processed color image' do
      let(:file_path) { File.join(FIXTURE_PATH, 'files', 'ocr_color_pre.tiff') }
      let(:result_path) { File.join(FIXTURE_PATH, 'files', 'ocr_color_pre.mono.tiff') }

      let(:file_uri) { "file://#{file_path}" }
      let(:kwargs) { { input_uris: [file_uri] } }

      it 'builds a monochrome image' do
        expect { generated_files }.not_to raise_error
        expect(File.exist?(result_path)).to be true
      end
    end

    context 'with monochrome image' do
      let(:file_path) { File.join(FIXTURE_PATH, 'files', 'ocr_mono.tiff') }
      let(:result_path) { file_path }

      it 'uses the existing monochrome image' do
        # do not delete result path, the file should stay put
        expect { generated_files }.not_to raise_error
        expect(File.exist?(result_path)).to be true
        expect(File.exist?(result_path.sub('.tiff', '.mono.tiff'))).to be_falsey
      end
    end
  end
end
