require "bunny"

module Flu
  class EventPublisher
    def initialize(logger, configuration)
      @logger        = logger
      @configuration = configuration
    end

    def publish(event, persistent=true)
      routing_key = event.to_routing_key
      @logger.debug("Publishing event with id '#{event.id}' with routing key: #{routing_key}")
      @exchange.publish(event.to_json, routing_key: routing_key, persistent: persistent)
      @logger.debug("Event published.")
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

    private

    def connect_to_exchange
      @connection = Bunny.new(host:     @configuration.rabbitmq_host,
                              port:     @configuration.rabbitmq_port,
                              user:     @configuration.rabbitmq_user,
                              password: @configuration.rabbitmq_password,
                              automatically_recover: true)
      @connection.start
      @channel  = @connection.create_channel
      @exchange = @channel.send(:topic,
                                @configuration.rabbitmq_exchange_name,
                                durable: @configuration.rabbitmq_exchange_durable)
    end
  end
end
