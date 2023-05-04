# frozen_string_literal: true

RSpec.describe DerivativeRodeo::Generators::BaseGenerator do
  let(:kwargs) { { input_uris: [] } }
  subject(:instance) { described_class.new(**kwargs) }

  %i[input_uris output_adapter_name output_extension generated_files].each do |method|
    it { is_expected.to respond_to(method) }
    it { is_expected.to respond_to("#{method}=") }
  end

  its(:output_extension) { is_expected.to be_nil }

  describe '#output_adapter_name' do
    subject(:output_adapter_name) { instance.output_adapter_name }

    context 'by default' do
      it { is_expected.to eq(DerivativeRodeo::StorageAdapters::SAME) }
    end

    context 'when given a value during instantation' do
      let(:kwargs) { { input_uris: [], output_adapter_name: 's3' } }
      it 'uses the given value' do
        expect(subject).to eq('s3')
      end
    end
  end

  describe '#build_step' do
    it 'must be defined by a child class' do
      expect { subject.build_step(in_file: nil, out_file: nil, in_tmp_path: nil) }.to raise_error(NotImplementedError)
    end
  end

  describe '#with_each_requisite_file_and_tmp_path' do
    it 'will return an array of StorageAdapters::BaseAdapter instances'
    it 'will yield two parameters: a StorageAdapters::BaseAdapter instance and a path to the temp file space'
  end
end
