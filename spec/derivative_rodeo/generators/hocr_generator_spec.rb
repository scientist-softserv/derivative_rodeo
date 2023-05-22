# frozen_string_literal: true

RSpec.describe DerivativeRodeo::Generators::HocrGenerator do
  let(:kwargs) { { input_uris: [], output_location_template: "" } }
  subject(:instance) { described_class.new(**kwargs) }

  %i[input_uris output_extension output_extension= generated_files].each do |method|
    it { is_expected.to respond_to(method) }
  end

  its(:output_extension) { is_expected.to eq('hocr') }

  describe '#generated_files' do
    let(:file_uri) { "file://#{file_path}" }
    let(:kwargs) { { input_uris: [file_uri] } }
    subject(:generated_files) { instance.generated_files }

    context 'with color image' do
      it 'builds a hocr file' do
        generated_files = nil
        Fixtures.with_file_uris_for("ocr_color.tiff") do |input_uris|
          Fixtures.with_temporary_directory do |output_temporary_path|
            output_location_template = "file://#{output_temporary_path}/{{ dir_parts[-1..-1] }}/{{basename}}.#{described_class.output_extension}"
            instance = described_class.new(input_uris: input_uris, output_location_template: output_location_template)
            generated_files = instance.generated_files

            expect(generated_files.all?(&:exist?)).to be_truthy
            # We extracted the text
            expect(File.foreach(generated_files.map(&:file_path).first).grep(/brigade/).any?).to be true
          end
        end
        expect(generated_files.all?(&:exist?)).to be_falsey
      end
    end

    context 'with pre processed color image' do
      it 'builds a hocr file' do
        generated_files = nil
        Fixtures.with_file_uris_for('ocr_color_pre.tiff') do |input_uris|
          Fixtures.with_temporary_directory do |output_temporary_path|
            output_location_template = "file://#{output_temporary_path}/{{ dir_parts[-1..-1] }}/{{basename}}.#{described_class.output_extension}"
            instance = described_class.new(input_uris: input_uris, output_location_template: output_location_template)
            generated_files = instance.generated_files

            expect(generated_files.all?(&:exist?)).to be_truthy
            # We extracted the text
            expect(File.foreach(generated_files.map(&:file_path).first).grep(/brigade/).any?).to be true
          end
        end
        expect(generated_files.all?(&:exist?)).to be_falsey
      end
    end

    context 'with an already mono file' do
      it 'builds a hocr file' do
        generated_files = nil
        Fixtures.with_file_uris_for('ocr_mono.tiff') do |input_uris|
          Fixtures.with_temporary_directory do |output_temporary_path|
            output_location_template = "file://#{output_temporary_path}/{{ dir_parts[0..-1] }}/{{basename}}.#{described_class.output_extension}"
            instance = described_class.new(input_uris: input_uris, output_location_template: output_location_template)
            generated_files = instance.generated_files

            expect(generated_files.all?(&:exist?)).to be_truthy
            # We extracted the text
            expect(File.foreach(generated_files.map(&:file_path).first).grep(/occasioned/).any?).to be true
          end
        end
        expect(generated_files.all?(&:exist?)).to be_falsey
      end
    end
  end
end
