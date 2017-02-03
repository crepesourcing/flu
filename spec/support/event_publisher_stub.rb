module Flu
  class InMemoryEventPublisher < EventPublisher

    attr_reader :published_events_by_routing_key

    def initialize(configuration)
      @logger                          = configuration.logger
      @configuration                   = configuration
      @published_events_by_routing_key = {}
    end

    def publish(event, persistent=true)
      routing_key                                    = event.to_routing_key
      published_events_by_routing_key[routing_key] ||= []
      published_events_by_routing_key[routing_key].push(event)
    end

    def connect
    end
  end
end
