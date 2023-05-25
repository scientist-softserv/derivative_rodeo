# frozen_string_literal: true

RSpec.describe DerivativeRodeo do
  it 'has a version number' do
    expect(DerivativeRodeo::VERSION).not_to be nil
  end

  its(:config) { is_expected.to be_a DerivativeRodeo::Configuration }
  its(:logger) { is_expected.to be_a Logger }
end
