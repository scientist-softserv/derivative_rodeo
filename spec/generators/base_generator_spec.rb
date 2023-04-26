# frozen_string_literal: true

RSpec.describe DerivativeZoo::Generator::BaseGenerator do
  let(:args) { { input_uris: [] } }
  subject { described_class.new(args) }

  it 'set the output adapter to same unless specified' do
    expect(subject.output_adapter_name).to eq('same')
  end

  context 'with a specified output adapter' do
    let(:args) { { input_uris: [], output_adapter_name: 's3' } }

    it 'set the output adapter to same unless specified' do
      expect(subject.output_adapter_name).to eq('s3')
    end
  end

  %i[input_uris output_adapter_name output_extension generated_files].each do |method|
    it "responds to #{method}" do
      expect(subject).to respond_to(method)
    end

    it "responds to #{method}=" do
      expect(subject).to respond_to("#{method}=")
    end
  end

  it 'requires build_step to be defined by a child class' do
    expect { subject.build_step(nil) }.to raise_error(NotImplementedError)
  end
end
