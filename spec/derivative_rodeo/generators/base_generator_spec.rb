# frozen_string_literal: true

RSpec.describe DerivativeRodeo::Generators::BaseGenerator do
  let(:kwargs) { { input_uris: [], output_target_template: "" } }
  subject(:instance) { described_class.new(**kwargs) }

  %i[input_uris output_adapter_name output_extension generated_files].each do |method|
    it { is_expected.to respond_to(method) }
    it { is_expected.to respond_to("#{method}=") }
  end

  its(:output_extension) { is_expected.to be_nil }

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
