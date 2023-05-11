# frozen_string_literal: true
require 'ostruct'
##
# This class is very rudimentary implementation of an SQS client.  It conforms to the necessary
# interface for sending messages and reading messages
#
# @see [DerivativeRodeo::StorageAdapters::SqsAdapter]
class AwsSqsFauxClient
  def initialize(queue_url: nil)
    @queue_url = queue_url || 'https://sqs.us-west-2.amazonaws.com/5555555555/fake'
    @storage = {}
  end
  attr_reader :storage

  def send_message(arg_hash)
    @storage[arg_hash[:queue_url]] ||= []
    @storage[arg_hash[:queue_url]] << arg_hash[:message_body]
  end

  def send_message_batch(arg_hash)
    @storage[arg_hash[:queue_url]] ||= []
    @storage[arg_hash[:queue_url]] += arg_hash[:entries]
  end

  def receive_message(arg_hash)
    output = []
    args_hash[:mx_number_of_messages].times do
      value = @storage[arg_hash[:queue_url]]&.pop
      output << value if value
    end
  end

  def get_queue_url(*)
    OpenStruct.new(queue_url: @queue_url)
  end
end
