module Flu
  module Dummy
    class EventPublisherDummy < Flu::EventPublisher
      def initialize(configuration)
        super(configuration)
      end

      def publish(event, persistent=true)
        routing_key = event.to_routing_key
        @logger.debug("Dummy Publishing event with id '#{event.id}' with routing key: #{routing_key}")
      end

      def connect
      end
    end
  end
end
