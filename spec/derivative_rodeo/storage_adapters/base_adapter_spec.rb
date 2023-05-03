# frozen_string_literal: true

RSpec.describe DerivativeRedeo::StorageAdapters::BaseAdapter do
  let(:args) { "fake://nothing" }

  subject { described_class.new(args) }
  xit "write specs for class methods"
  xit "write specs for instance methods"

  it "should require a file_uri" do
    expect { described_class.new }.to raise_error(ArgumentError)
  end

  it "should set the file_uri on initialize" do
    expect(subject.file_uri).to eq(args)
  end
end
