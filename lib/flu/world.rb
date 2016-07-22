require "base64"
require "bunny"

module Flu
  class World
    def initialize(logger, configuration)
      @logger        = logger
      @configuration = configuration
    end

    def connect_to_exchange
      @connection = Bunny.new(host: @configuration.rabbitmq_host,
                              port: @configuration.rabbitmq_port,
                              user: @configuration.rabbitmq_user,
                              password: @configuration.rabbitmq_password,
                              automatically_recover: true)
      @connection.start
      @channel  = @connection.create_channel
      @exchange = @channel.send(@configuration.rabbitmq_exchange_type,
                                @configuration.rabbitmq_exchange_name,
                                durable: @configuration.rabbitmq_exchange_durable)
    end

    def spread(data)
      mapped_object = map_complex_object(data)
      @exchange.publish(mapped_object.to_json)
    end

    private

    def map_complex_object(object)
      if object.is_a?(Array)
        map_array(object)
      elsif object.is_a?(Hash)
        map_hash(object)
      elsif object.is_a?(ActionDispatch::Http::UploadedFile)
        map_file(object)
      else
        object
      end
    end

    def map_array(object)
      array = []
      object.each do |value|
        array.push(map_complex_object(value))
      end
      array
    end

    def map_hash(object)
      hash = {}
      object.each do |key, value|
        hash[key] = map_complex_object(value)
      end
      hash
    end

    def map_file(object)
      {
        "file_name":    object.original_filename,
        "content_type": object.content_type,
        "content":      Base64.encode64(object.tempfile.read)
      }
    end

    def connect
      connected = false
      while !connected
        begin
          connect_to_exchange
          connected = true
        rescue Bunny::TCPConnectionFailedForAllHosts
          @logger.warn("RabbitMQ connection failed, try again in 1 second.")
          sleep 1
        end
      end
    end
  end
end
