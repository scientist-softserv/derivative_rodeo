# frozen_string_literal: true

require 'aws-sdk-sqs'
require 'cgi'

ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.uncountable 'sqs'
end

module DerivativeRodeo
  module StorageLocations
    ##
    # Location to download and upload files to Sqs
    # It uploads a file_uri to the queue, not the contents of that file
    # reading from the queue is not currently implemented
    #
    # rubocop:disable Metrics/ClassLength
    class SqsLocation < BaseLocation
      ##
      # @!group Class Attributes
      #
      # @!attribute batch_size
      #   @return [Integer]
      class_attribute :batch_size, default: 10

      # @!attribute use_real_sqs
      #   When true, use the real SQS; else when false use a fake one.  You probably don't want to
      #   use the fake one in your production.  But it's exposed in this manner to ease testing of
      #   downstream dependencies.
      class_attribute :use_real_sqs, default: true
      # @!endgroup Class Attributes
      ##

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
        raise Errors::MaxQqueueSize(batch_size: batch_size) if batch_size > config.aws_sqs_max_batch_size
        batch = []
        Dir.glob("#{File.dirname(tmp_file_path)}/**/**").each.with_index do |fp, i|
          batch << { id: SecureRandom.uuid, message_body: output_json("file://#{fp}") }
          if (i + 1 % batch_size).zero?
            add_batch(messages: batch)
            batch = []
          end
        end

        # Ensure we're flushing the batched up queue as part of completing the write.
        add_batch(messages: batch) if batch.present?
        file_uri
      end

      # rubocop:disable Metrics/MethodLength
      def client
        @client ||= if use_real_sqs?
                      if config.aws_sqs_access_key_id && config.aws_sqs_secret_access_key
                        Aws::SQS::Client.new(
                          region: config.aws_sqs_region,
                          credentials: Aws::Credentials.new(
                            config.aws_sqs_access_key_id,
                            config.aws_sqs_secret_access_key
                          )
                        )
                      else
                        Aws::SQS::Client.new(region: config.aws_sqs_region)
                      end
                    else
                      # We are not requiring this file; except in the spec context.
                      AwsSqsFauxClient.new
                    end
      end
      # rubocop:enable Metrics/MethodLength

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
        @file_path ||= [file_dir, file_name].join('/')
      end

      def file_dir
        @file_dir ||= file_uri_parts[:file_dir]
      end

      ##
      # @api private
      def file_name
        @file_name ||= file_uri_parts[:file_name]
      end

      def template
        params&.[]('template')&.first
      end

      def scheme
        file_uri_parts&.[](:scheme)
      end

      def params
        @params ||= CGI.parse(file_uri_parts[:query]) if file_uri_parts[:query]
      end

      def output_json(uri)
        # TODO: Add ability to handle a pre-process-template given to an SQS, and pass that along to the generator when applicable.
        key = DerivativeRodeo::Services::ConvertUriViaTemplateService.call(from_uri: uri, template: template, adapter: self)
        { key => [template] }.to_json
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
        @file_uri_parts[:file_dir] = path_parts&.[](3..-2)&.join('/')
        @file_uri_parts
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
