# frozen_string_literal: true

RSpec.describe DerivativeRodeo::Generators::BaseGenerator do
  let(:kwargs) { { input_uris: [], output_location_template: "" } }
  subject(:instance) { described_class.new(**kwargs) }

  %i[input_uris output_extension output_extension= generated_files].each do |method|
    it { is_expected.to respond_to(method) }
  end

  its(:output_extension) { is_expected.to be_nil }

  describe '#input_uris' do
    subject { instance.input_uris }
    context 'when given a String' do
      let(:kwargs) { { input_uris: '123', output_location_template: "" } }
      it { is_expected.to be_a(Array) }
    end

    context 'when given an Array' do
      let(:kwargs) { { input_uris: ['123'], output_location_template: "" } }

      it "uses the given array" do
        expect(subject).to match_array(kwargs.fetch(:input_uris))
      end
    end
  end

  describe '#build_step' do
    it 'must be defined by a child class' do
      expect { subject.build_step(input_location: nil, output_location: nil, input_tmp_file_path: nil) }.to raise_error(NotImplementedError)
    end
  end

  describe '#destination' do
    context 'when the output already exists' do
      it 'returns the file at the output location' do
        Fixtures.with_temporary_directory do |output_location_dir|
          # Ensure that we have the file in the output location.
          output_location = File.join(output_location_dir, File.basename(__FILE__))
          FileUtils.cp(__FILE__, output_location)
          template = "file://#{output_location}"

          input_uri = "file://#{__FILE__}"
          instance = described_class.new(input_uris: [input_uri], output_location_template: template)
          input_file = DerivativeRodeo::StorageLocations::BaseLocation.from_uri(input_uri)
          destination = instance.destination(input_file)
          expect(destination.file_path).to eq(output_location)
          expect(destination.exist?).to be_truthy
        end
      end
    end

    context 'when the output does not exist and the preprocessed location exists' do
      it 'returns the file at the preprocessed location' do
        Fixtures.with_temporary_directory do |output_location_dir|
          Fixtures.with_temporary_directory do |preprocessed_location_dir|
            output_location = File.join(output_location_dir, File.basename(__FILE__))
            output_template = "file://#{output_location}"

            preprocessed_location = File.join(preprocessed_location_dir, File.basename(__FILE__))
            preprocessed_template = "file://#{preprocessed_location}"
            FileUtils.cp(__FILE__, preprocessed_location)

            input_uri = "file://#{__FILE__}"

            instance = described_class.new(
              input_uris: [input_uri],
              output_location_template: output_template,
              preprocessed_location_template: preprocessed_template
            )

            input_file = DerivativeRodeo::StorageLocations::BaseLocation.from_uri(input_uri)
            destination = instance.destination(input_file)

            expect(destination.file_path).to eq(preprocessed_location)
            expect(destination.exist?).to be_truthy

            expect(File.exist?(output_location)).to be_falsey
          end
        end
      end

      context 'when neither the output nor the preprocessed location exists' do
        it 'returns the file handle at the output location (which does not exist)' do
          Fixtures.with_temporary_directory do |output_location_dir|
            Fixtures.with_temporary_directory do |preprocessed_location_dir|
              output_location = File.join(output_location_dir, File.basename(__FILE__))
              output_template = "file://#{output_location}"

              preprocessed_location = File.join(preprocessed_location_dir, File.basename(__FILE__))
              preprocessed_template = "file://#{preprocessed_location}"

              input_uri = "file://#{__FILE__}"

              instance = described_class.new(
                input_uris: [input_uri],
                output_location_template: output_template,
                preprocessed_location_template: preprocessed_template
              )

              input_file = DerivativeRodeo::StorageLocations::BaseLocation.from_uri(input_uri)
              destination = instance.destination(input_file)

              expect(destination.file_path).to eq(output_location)
              expect(destination.exist?).to be_falsey

              expect(File.exist?(output_location)).to be_falsey
            end
          end
        end
      end
    end

    describe '#with_each_requisite_file_and_tmp_path' do
      it 'will return an array of StorageLocations::BaseLocation instances'
      it 'will yield two parameters: a StorageLocations::BaseLocation instance and a path to the temp file space'
    end
  end
end
