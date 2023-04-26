# frozen_string_literal: true

RSpec.describe DerivativeZoo do
  it 'has a version number' do
    expect(DerivativeZoo::VERSION).not_to be nil
  end

  it 'loads a configuration object' do
    expect(subject.config).to be_a DerivativeZoo::Configuration
  end

  [
    DerivativeZoo::ExtensionMissingError,
    DerivativeZoo::FileMissingError,
    DerivativeZoo::StorageAdapterMissing,
    DerivativeZoo::StorageAdapterNotFoundError
  ].each do |klass|
    it "raise raise #{klass} when needed" do
      expect { raise klass }.to raise_error(klass)
    end
  end
end
