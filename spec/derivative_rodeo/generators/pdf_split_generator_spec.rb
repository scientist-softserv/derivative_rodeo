# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DerivativeRodeo::Generators::PdfSplitGenerator do
  let(:kwargs) { { input_uris: [], output_location_template: nil } }
  subject(:instance) { described_class.new(**kwargs) }

  %i[input_uris output_extension output_extension= generated_files].each do |method|
    it { is_expected.to respond_to(method) }
  end

  it { is_expected.to be_a(DerivativeRodeo::Generators::CopyFileConcern) }

  context 'by default' do
    its(:output_extension) { is_expected.to eq('tiff') }
    its(:pdf_splitter_name) { is_expected.to eq(:tiff) }
  end

  context 'when you change the #output_extension' do
    it 'changes the #pdf_splitter_name' do
      expect { instance.output_extension = 'png' }.to change(instance, :pdf_splitter_name).from(:tiff).to(:png)
    end
  end

  describe '#generated_files' do
    context 'when given a PDF to split' do
      it 'will create one image per page, writing that to the storage adapter, and then enqueue each page for processing' do
        generated_files = nil
        Fixtures.with_file_uris_for("minimal-2-page.pdf") do |input_uris|
          Fixtures.with_temporary_directory do |output_temporary_path|
            output_location_template = "file://#{output_temporary_path}/{{dir_parts[0..-1]}}/{{ filename }}"
            instance = described_class.new(input_uris: input_uris, output_location_template: output_location_template)
            generated_files = instance.generated_files

            # Note the above PDF is 2 pages!
            expect(generated_files.size).to eq(2)

            # We want this split according to the output extension.
            expect(generated_files.all? { |f| f.file_uri.end_with?(".#{described_class.output_extension}") }).to be_truthy

            # The generated files should exist during this test
            expect(generated_files.all?(&:exist?)).to be_truthy
          end
        end

        # Did we clean this up
        expect(generated_files.any?(&:exist?)).to be_falsey
      end
    end
  end
end
