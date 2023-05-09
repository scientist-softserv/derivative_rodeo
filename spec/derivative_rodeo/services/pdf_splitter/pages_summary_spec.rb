# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DerivativeRodeo::Services::PdfSplitter::PagesSummary do
  describe '.extract_from' do
    let(:command_stdout) do
      File.new(Fixtures.path_for('pdfimages-poppler-greater-than-0.25.txt'))
    end

    before do
      allow(Open3).to receive(:popen3).and_yield(nil, command_stdout, nil, nil)
    end

    # Yes this is not a PDF
    subject { described_class.extract_from(path: __FILE__) }

    it { is_expected.to be_a described_class }

    context 'using pdfimages shell command' do
      it 'determines the page_count of the given PDF' do
        expect(subject.page_count).to eq(3)
      end
      it 'determines the height of the given PDF' do
        expect(subject.height).to eq(30)
      end
      it 'determines the width of the given PDF' do
        expect(subject.width).to eq(3)
      end

      it 'determines the bits_per_channel of the given PDF' do
        expect(subject.bits_per_channel).to eq(8)
      end

      it 'determines the color_description of the given PDF' do
        expect(subject.color_description).to eq('rgb')
      end

      it 'determines the channels of the given PDF' do
        expect(subject.channels).to eq(3)
      end

      it 'determines the color of the given PDF' do
        expect(subject.color).to eq(['rgb', 3, 8])
      end

      it 'determines the pixels per inch (ppi) of the given PDF' do
        expect(subject.pixels_per_inch).to eq(400)
      end

      it { is_expected.to respond_to(:ppi) }
    end
  end
end
