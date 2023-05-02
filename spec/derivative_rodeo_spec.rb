# frozen_string_literal: true

RSpec.describe DerivativeRedeo do
  it 'has a version number' do
    expect(DerivativeRedeo::VERSION).not_to be nil
  end

  it 'loads a configuration object' do
    expect(subject.config).to be_a DerivativeRedeo::Configuration
  end

  [
    DerivativeRedeo::ExtensionMissingError,
    DerivativeRedeo::FileMissingError,
    DerivativeRedeo::StorageAdapterMissing,
    DerivativeRedeo::StorageAdapterNotFoundError
  ].each do |klass|
    it "raise raise #{klass} when needed" do
      expect { raise klass }.to raise_error(klass)
    end
  end
end
