module Flu
  class QueueRepositoryStub < QueueRepository
    attr_reader :management_client

    def create_management_client(configuration)
      double("RabbitMQ Management Client")
    end
  end
end
