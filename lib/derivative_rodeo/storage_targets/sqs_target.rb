# frozen_string_literal: true

require 'aws-sdk-sqs'

module DerivativeRodeo
  module StorageTargets
    ##
    # Target to download and upload files to Sqs
    #
    class SqsTarget < BaseTarget
      class_attribute :batch_size, default: 10

      attr_writer :client

      ##
      # Create a new uri of the classes type. Parts argument should have a default in
      # implementing classes. Must support a number or the symbol :all
      #
      # @api public
      #
      # @param path [String]
      # @param parts [Integer, :all], defaults to 1 for Sqs which is file_name.ext. We use 1 because it helps with tmp files, but the actual sqs queue does not have a file path
      # @return [String]
      def self.create_uri(path:, parts: 1)
        file_path = file_path_from_parts(path: path, parts: parts)
        "sqs://#{DerivativeRodeo.config.aws_sqs_queue}.sqs.#{DerivativeRodeo.config.aws_sqs_region}.amazonaws.com/#{file_path}"
      end

      ##
      # @api public
      # download or copy the file to a tmp path
      # deletes the tmp file after the block is executed
      #
      # @return [String] the path to the tmp file
      def with_existing_tmp_path(&block)
        with_tmp_path(lambda { |_file_path, tmp_file_path, exist|
                        raise Errors::FileMissingError unless exist
                        File.open(tmp_file_path, 'w') do |file|
                          read_batch.each do |message|
                            file.write(message)
                          end
                        end
                      }, &block)
      end

      ##
      # @api public
      #
      # Existance is futile
      # @return [Boolean]
      def exist?
        bucket.objects(prefix: file_path).count.positive?
      end

      ##
      # @api public
      # write the tmp file to the file_uri
      #
      # @return [String] the file_uri
      def write
        raise Errors::FileMissingError("Use write within a with__new_tmp_path block and fille the mp file with data before writing") unless File.exist?(tmp_file_path)
        raise Errors::MaxQqueueSize(batch_size: batch_size) if batch_size > DerivativeRodeo.config.aws_sqs_max_batch_size
        batch = []
        File.foreach(tmp_file_path).with_index do |line, i|
          batch << { id: i.to_s, message_body: [line].to_json }
          if (i % batch_size).zero?
            add_batch(messages: batch)
            batch = []
          end
        end
        file_uri
      end

      def client
        @client ||= if DerivativeRodeo.config.aws_sqs_access_key_id && DerivativeRodeo.config.aws_sqs_secret_access_key
                      Aws::SQS::Client.new(
                        region: DerivativeRodeo.config.aws_sqs_region,
                        credentials: Aws::Credentials.new(
                          DerivativeRodeo.config.aws_sqs_access_key_id,
                          DerivativeRodeo.config.aws_sqs_secret_access_key
                        )
                      )
                    else
                      Aws::SQS::Client.new(region: DerivativeRodeo.config.aws_sqs_region)
                    end
      end

      def add_batch(messages:)
        client.send_message_batch({
                                    queue_url: queue_url,
                                    entries: messages.to_json
                                  })
      end

      def read_batch
        raise Errors::MaxQqueueSize(batch_size: batch_size) if batch_size > DerivativeRodeo.config.aws_sqs_max_batch_size

        response = client.receive_message({
                                            queue_url: queue_url,
                                            max_number_of_messages: batch_size
                                          })
        response.messages.map do |message|
          JSON.parse(message.body)
        end
      end

      def queue_url
        @queue_url ||= client.get_queue_url(queue_name: queue_name).queue_url
      end

      ##
      # @api private
      # https://fancy-queue-name.sqs.eu-west-1.amazonaws.com/file.tld
      def queue_name
        @queue_name ||= file_uri.match(%r{sqs://(.+)\.sqs})&.[](1)
      rescue StandardError
        raise Errors::QueueMissingError
      end
    end
  end
end
