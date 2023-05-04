# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DerivativeRodeo::Generators::PdfSplitGenerator do
  let(:kwargs) { { input_uris: [] } }
  subject(:instance) { described_class.new(**kwargs) }

  %i[input_uris output_adapter_name output_extension generated_files].each do |method|
    it { is_expected.to respond_to method }
    it { is_expected.to respond_to "#{method}=" }
  end

  context 'by default' do
    its(:output_extension) { is_expected.to eq('tiff') }
    its(:pdf_splitter_name) { is_expected.to eq(:tiff) }
  end

  context 'when you change the #output_extension' do
    it 'changes the #pdf_splitter_name' do
      expect { instance.output_extension = 'png' }.to change(instance, :pdf_splitter_name).from(:tiff).to(:png)
    end
  end

  describe '#generate_files' do
    context 'when given a PDF to split it will create one image per page, writing that to the storage adapter, and then enqueue each page for processing'
  end
end
