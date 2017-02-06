RSpec.configure do |rspec|
  rspec.shared_context_metadata_behavior = :apply_to_host_groups
end

RSpec.shared_context "controllers defined", :shared_context => :metadata do
  before(:all) do
    set_application_name("ninja_app")
    @event_factory   = Flu::EventFactory.new(Flu.config)
    @event_publisher = Flu::InMemoryEventPublisher.new(Flu.config)
    @logger          = Logger.new(STDOUT)

    Flu::ActionControllerExtender.extend_controllers(@event_factory, @event_publisher, @logger)

    class ApplicationController < ActionController::Base
      def create
        self.response_body = "created"
      end
      def update
        self.response_body = "updated"
      end
      def destroy
        self.response_body = "destroyed"
      end
      def show
        self.response_body = "shown"
      end
      def index
        self.response_body = "indexed"
      end
    end

    class DynastiesController < ApplicationController
    end

    class NinjasController < ApplicationController
      track_requests user_metadata: lambda {
        {
          current_user_id: current_user ? current_user.id : nil,
          client_id:       request.headers["Client-Id"],
        }
      }
    end
  end

  after(:each) do
    @event_publisher.clear
  end
end

RSpec.configure do |rspec|
  rspec.include_context "controllers defined", :include_shared => true
end
