# frozen_string_literal: true

RSpec.describe DerivativeRodeo::StorageLocations::BaseLocation do
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

  describe '.location_name' do
    subject { described_class.location_name }
    it { is_expected.to be_a(String) }
  end

  describe '.scheme' do
    subject { described_class.scheme }
    it { is_expected.to be_a(String) }
  end

  describe '.file_path_from_parts' do
    subject { described_class.file_path_from_parts(path: path, parts: parts) }
    [
      { path: "/hello/world", parts: 1, expected: "world" }
    ].each do |hash|
      context "with path: #{hash.fetch(:path).inspect} and parts: #{hash.fetch(:parts).inspect}" do
        let(:path) { hash.fetch(:path) }
        let(:parts) { hash.fetch(:parts) }
        it { is_expected.to eq(hash.fetch(:expected)) }
      end
    end
  end
end
