# frozen_string_literal: true

RSpec.describe DerivativeRodeo::Generators::BaseGenerator do
  let(:kwargs) { { input_uris: [], output_target_template: "" } }
  subject(:instance) { described_class.new(**kwargs) }

  %i[input_uris output_extension output_extension= generated_files].each do |method|
    it { is_expected.to respond_to(method) }
  end

  its(:output_extension) { is_expected.to be_nil }

  describe '#build_step' do
    it 'must be defined by a child class' do
      expect { subject.build_step(input_target: nil, output_target: nil, input_tmp_file_path: nil) }.to raise_error(NotImplementedError)
    end
  end

  describe '#destination' do
    context 'when the output already exists' do
      it 'returns the file at the output target' do
        Fixtures.with_temporary_directory do |output_target_dir|
          # Ensure that we have the file in the output target.
          output_target = File.join(output_target_dir, File.basename(__FILE__))
          FileUtils.cp(__FILE__, output_target)
          template = "file://#{output_target}"

          input_uri = "file://#{__FILE__}"
          instance = described_class.new(input_uris: [input_uri], output_target_template: template)
          input_file = DerivativeRodeo::StorageTargets::BaseTarget.from_uri(input_uri)
          destination = instance.destination(input_file)
          expect(destination.file_path).to eq(output_target)
          expect(destination.exist?).to be_truthy
        end
      end
    end

    context 'when the output does not exist and the preprocessed target exists' do
      it 'returns the file at the preprocessed target' do
        Fixtures.with_temporary_directory do |output_target_dir|
          Fixtures.with_temporary_directory do |preprocessed_target_dir|
            output_target = File.join(output_target_dir, File.basename(__FILE__))
            output_template = "file://#{output_target}"

            preprocessed_target = File.join(preprocessed_target_dir, File.basename(__FILE__))
            preprocessed_template = "file://#{preprocessed_target}"
            FileUtils.cp(__FILE__, preprocessed_target)

            input_uri = "file://#{__FILE__}"

            instance = described_class.new(
              input_uris: [input_uri],
              output_target_template: output_template,
              preprocessed_target_template: preprocessed_template
            )

            input_file = DerivativeRodeo::StorageTargets::BaseTarget.from_uri(input_uri)
            destination = instance.destination(input_file)

            expect(destination.file_path).to eq(preprocessed_target)
            expect(destination.exist?).to be_truthy

            expect(File.exist?(output_target)).to be_falsey
          end
        end
      end

      context 'when neither the output nor the preprocessed target exists' do
        it 'returns the file handle at the output target (which does not exist)' do
          Fixtures.with_temporary_directory do |output_target_dir|
            Fixtures.with_temporary_directory do |preprocessed_target_dir|
              output_target = File.join(output_target_dir, File.basename(__FILE__))
              output_template = "file://#{output_target}"

              preprocessed_target = File.join(preprocessed_target_dir, File.basename(__FILE__))
              preprocessed_template = "file://#{preprocessed_target}"

              input_uri = "file://#{__FILE__}"

              instance = described_class.new(
                input_uris: [input_uri],
                output_target_template: output_template,
                preprocessed_target_template: preprocessed_template
              )

              input_file = DerivativeRodeo::StorageTargets::BaseTarget.from_uri(input_uri)
              destination = instance.destination(input_file)

              expect(destination.file_path).to eq(output_target)
              expect(destination.exist?).to be_falsey

              expect(File.exist?(output_target)).to be_falsey
            end
          end
        end
      end
    end

    describe '#with_each_requisite_file_and_tmp_path' do
      it 'will return an array of StorageTargets::BaseTarget instances'
      it 'will yield two parameters: a StorageTargets::BaseTarget instance and a path to the temp file space'
    end
  end
end
