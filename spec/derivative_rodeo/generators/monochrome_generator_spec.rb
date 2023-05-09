# frozen_string_literal: true

RSpec.describe DerivativeRodeo::Generators::MonochromeGenerator do
  let(:kwargs) { { input_uris: [], output_target_template: "" } }
  subject(:instance) { described_class.new(**kwargs) }

  %i[input_uris output_extension output_extension= generated_files].each do |method|
    it { is_expected.to respond_to(method) }
  end

  its(:output_extension) { is_expected.to eq('mono.tiff') }

  describe '#generated_files' do
    let(:file_uri) { "file://#{file_path}" }
    let(:kwargs) { { input_uris: [file_uri] } }
    subject(:generated_files) { instance.generated_files }

    describe '#generated_files' do
      context 'with pre processed color image' do
        it 'builds a monochrome image' do
          generated_files = nil
          Fixtures.with_file_uris_for("ocr_color_pre.tiff") do |input_uris|
            Fixtures.with_temporary_directory do |output_temporary_path|
              output_target_template = "file://#{output_temporary_path}/{{ dir_parts[0..-1] }}/{{basename}}.#{described_class.output_extension}"
              instance = described_class.new(input_uris: input_uris, output_target_template: output_target_template)
              generated_files = instance.generated_files

              expect(generated_files.all?(&:exist?)).to be_truthy
            end

            # Because we are working with a color image, the generated image lives only within the
            # scope of the above `Fixtures.with_file_uris_for` scope
            expect(generated_files.all?(&:exist?)).to be_falsey
          end
          expect(generated_files.all?(&:exist?)).to be_falsey
        end
      end

      context 'with monochrome image' do
        it 'uses the existing monochrome image' do
          generated_files = nil
          Fixtures.with_file_uris_for("ocr_mono.tiff") do |input_uris|
            Fixtures.with_temporary_directory do |output_temporary_path|
              output_target_template = "file://#{output_temporary_path}/{{ dir_parts[0..-1] }}/{{basename}}.#{described_class.output_extension}"
              instance = described_class.new(input_uris: input_uris, output_target_template: output_target_template)
              generated_files = instance.generated_files

              expect(generated_files.all?(&:exist?)).to be_truthy
            end

            # We are re-using the existing mono chrome file; and thus have the same URI.
            expect(generated_files.all?(&:exist?)).to be_truthy
          end
          expect(generated_files.all?(&:exist?)).to be_falsey
        end
      end
    end
  end
end
