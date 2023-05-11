# frozen_string_literal: true

require 'aws-sdk-sqs'
require 'cgi'

module DerivativeRodeo
  module StorageTargets
    ##
    # Target to download and upload files to Sqs
    # It uploads a file_uri to the queue, not the contents of that file
    # reading from the queue is not currently implemented
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
        "#{adapter_prefix}#{file_path}"
      end

      def self.adapter_prefix(config: DerivativeRodeo.config)
        "#{scheme}://#{config.aws_sqs_region}.amazonaws.com/#{config.aws_sqs_account_id}/#{config.aws_sqs_queue}/"
      end

      # TODO: implement read
      # ##
      # # @api public
      # # download or copy the file to a tmp path
      # # deletes the tmp file after the block is executed
      # #
      # # @return [String] the path to the tmp file
      # def with_existing_tmp_path(&block)
      #   with_tmp_path(lambda { |_file_path, tmp_file_path, exist|
      #                   raise Errors::FileMissingError unless exist
      #                   File.open(tmp_file_path, 'w') do |file|
      #                     read_batch.each do |message|
      #                       file.write(message)
      #                     end
      #                   end
      #                 }, &block)
      # end

      ##
      # @api public
      #
      # Existance is futile. And there's not way to check if a specific item is in an sqs queue
      # @return [Boolean]
      def exist?
        false
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
        Dir.glob("#{File.dirname(tmp_file_path)}/**/**").each.with_index do |fp, i|
          batch << { id: SecureRandom.uuid, message_body: output_uri("file://#{fp}") }
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

      def add(message:)
        client.send_message({
                              queue_url: queue_url,
                              message_body: message
                            })
      end

      def add_batch(messages:)
        client.send_message_batch({
                                    queue_url: queue_url,
                                    entries: messages
                                  })
      end

      # def read_batch
      #   raise Errors::MaxQqueueSize(batch_size: batch_size) if batch_size > DerivativeRodeo.config.aws_sqs_max_batch_size

      #   response = client.receive_message({
      #                                       queue_url: queue_url,
      #                                       max_number_of_messages: batch_size
      #                                     })
      #   response.messages.map do |message|
      #     JSON.parse(message.body)
      #   end
      # end

      def queue_url
        @queue_url ||= client.get_queue_url(queue_name: queue_name).queue_url
      end

      ##
      # @api private
      def queue_name
        @queue_name ||= file_uri_parts[:queue_name]
      rescue StandardError
        raise Errors::QueueMissingError
      end

      ##
      # @api private
      def file_path
        @file_path ||= file_uri_parts[:file_path]
      end

      def template
        params&.[]('template')&.first
      end

      def scheme
        file_uri_parts&.[](:scheme)
      end

      def output_uri(uri)
        DerivativeRodeo::Services::ConvertUriViaTemplateService.call(from_uri: uri, template: template, adapter: self)
      end

      def params
        @params ||= CGI.parse(file_uri_parts[:query]) if file_uri_parts[:query]
      end

      def file_uri_parts
        return @file_uri_parts if @file_uri_parts
        uri = URI.parse(file_uri)
        @file_uri_parts = uri&.component&.inject({}) do |hash, component|
          hash[component] = uri.send(component)
          hash
        end
        @file_uri_parts[:region] = @file_uri_parts[:host]&.split('.')&.[](0)
        path_parts = @file_uri_parts[:path]&.split('/')
        @file_uri_parts[:account_id] = path_parts&.[](1)
        @file_uri_parts[:queue_name] = path_parts&.[](2)
        @file_uri_parts[:file_name] = path_parts&.[](-1)
        @file_uri_parts[:file_path] = path_parts&.[](3..-2)&.join('/')
        @file_uri_parts
      end
    end
  end
end
