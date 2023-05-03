# frozen_string_literal: true

RSpec.describe DerivativeRodeo do
  it 'has a version number' do
    expect(DerivativeRodeo::VERSION).not_to be nil
  end

  it 'loads a configuration object' do
    expect(subject.config).to be_a DerivativeRodeo::Configuration
  end
end
