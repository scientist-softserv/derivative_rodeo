# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DerivativeRedeo::Configuration do
  subject(:instance) { described_class.new }
  context '#logger' do
    subject(:logger) { instance.logger }

    it { is_expected.to respond_to(:error) }
    it { is_expected.to respond_to(:fatal) }
    it { is_expected.to respond_to(:info) }
    it { is_expected.to respond_to(:warn) }
    context 'default log level' do
      subject { logger.level }
      it { is_expected.to eq(Logger::FATAL) }
    end
  end

  it { is_expected.to respond_to :aws_s3_region }
  it { is_expected.to respond_to :aws_s3_bucket }
  it { is_expected.to respond_to :aws_s3_access_key_id }
  it { is_expected.to respond_to :aws_s3_secret_access_key }
  it { is_expected.to respond_to :aws_sqs_region }
  it { is_expected.to respond_to :aws_sqs_queue }
  it { is_expected.to respond_to :aws_sqs_access_key_id }
  it { is_expected.to respond_to :aws_sqs_secret_access_key }
  it { is_expected.to respond_to :aws_sqs_max_batch_size }
end
