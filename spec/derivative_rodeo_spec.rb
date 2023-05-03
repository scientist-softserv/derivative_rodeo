# frozen_string_literal: true

RSpec.describe DerivativeRodeo do
  it 'has a version number' do
    expect(DerivativeRodeo::VERSION).not_to be nil
  end

  it 'loads a configuration object' do
    expect(subject.config).to be_a DerivativeRodeo::Configuration
  end

  [
    DerivativeRodeo::ExtensionMissingError,
    DerivativeRodeo::FileMissingError,
    DerivativeRodeo::StorageAdapterMissing,
    DerivativeRodeo::StorageAdapterNotFoundError
  ].each do |klass|
    it "raise raise #{klass} when needed" do
      expect { raise klass }.to raise_error(klass)
    end
  end
end
