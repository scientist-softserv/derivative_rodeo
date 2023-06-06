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
  end

  describe '.filename_for_a_derived_page_from_a_pdf?' do
    subject { described_class.filename_for_a_derived_page_from_a_pdf?(filename: filename, extension: extension) }
    [
      ["hello--page-a.tiff", 'tiff', false],
      ["hello--page-1.tiff", nil, true], # It uses filename's extension
      ["hello--page-1.tiff", '.tiff', true],
      ["hello-page-1.tiff", '.tiff', false], # Does not have leading double dash
      ["hello--page-1.png", '.tiff', false], # Wrong file extension
      ["hello--page-1.tiffany", '.tiff', false] # Additional words at end of filename
    ].each do |given_filename, given_extension, expected_result|
      context "for filename: #{given_filename.inspect} and extension: #{given_extension.inspect}" do
        let(:filename) { given_filename }
        let(:extension) { given_extension }
        it { is_expected.to eq(expected_result) }
      end
    end
  end

  describe '#generated_files' do
    context 'when given an already split PDF' do
      it 'uses the already split components' do
        Fixtures.with_file_uris_for("minimal-2-page.pdf") do |input_uris|
          Fixtures.with_temporary_directory do |output_temporary_path|
            output_location_template = "file://#{output_temporary_path}/{{ dir_parts[-1..-1] }}/{{ filename }}"
            instance = described_class.new(input_uris: input_uris, output_location_template: output_location_template)
            output_location = DerivativeRodeo::StorageLocations::FileLocation.build(from_uri: input_uris.first, template: output_location_template)

            # Let's fake a nice TIFF being in a pre-processed location.
            pre_existing_tiff_path = File.join(output_location.file_dir, "#{output_location.file_basename}--page-1.tiff")
            FileUtils.mkdir_p(File.dirname(pre_existing_tiff_path))
            File.open(pre_existing_tiff_path, "w+") do |f|
              f.puts "🤠🐮🐴 A muppet man parading as a TIFF."
            end

            generated_files = instance.generated_files
            # TODO: The PDF is two pages yet we only check for the presence of one
            # or more derived files; hence our faked pre-processed derivative is all that we find.
            expect(generated_files.size).to eq(1)

            # Ensuring that we do in fact have the pre-made file.
            expect(File.read(generated_files.first.file_path)).to start_with("🤠🐮🐴")
          end
        end
      end
    end

    context 'when given a PDF to split' do
      it 'will create one image per page, writing that to the storage adapter, and then enqueue each page for processing' do
        generated_files = nil
        Fixtures.with_file_uris_for("minimal-2-page.pdf") do |input_uris|
          Fixtures.with_temporary_directory do |output_temporary_path|
            output_location_template = "file://#{output_temporary_path}/{{dir_parts[-1..-1]}}/{{ filename }}"
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
