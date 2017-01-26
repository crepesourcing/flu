require "rabbitmq/http/client"

module Flu
  class QueueRepository
    def initialize(logger, configuration)
      @logger            = logger
      @configuration     = configuration
      @management_client = RabbitMQ::HTTP::Client.new("http://#{@configuration.rabbitmq_host}:#{@configuration.rabbitmq_management_port}/",
                                                      username: @configuration.rabbitmq_user,
                                                      password: @configuration.rabbitmq_password)
    end

    def find_all
      @management_client.list_queues
    end

    def find_queue(name)
      @management_client.queue_info("/", name)
    end

    def find_bindings_for_queue(name)
      @management_client.list_queue_bindings("/", name)
    end

    def purge_queue(name)
      @management_client.purge_queue("/", name)
    end

    def delete_queue(name)
      @management_client.delete_queue("/", name)
    end

    def queue_names_that_match(matcher)
      ## TODO
    end
  end
end
