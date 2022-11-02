RSpec.configure do |rspec|
  rspec.shared_context_metadata_behavior = :apply_to_host_groups
end

RSpec.shared_context "active records defined", :shared_context => :metadata do
  before(:all) do
    set_application_name("ninja_app")
    @event_factory   = Flu::EventFactory.new(Flu.config)
    @event_publisher = Flu::Dummy::InMemoryEventPublisher.new(Flu.config)
    Flu::ActiveRecordExtender.extend_models(@event_factory, @event_publisher)

    ActiveRecord::Migration.verbose = false
    @connection = ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

    ActiveRecord::Schema.define(:version => 1) do
      create_table :dynasties do |t|
        t.string  :name
        t.integer :year
        t.timestamps
      end
      create_table :ninjas do |t|
        t.string  :name
        t.integer :dynasty_id
        t.string  :color
        t.integer :height
        t.integer :weight
        t.timestamps
      end
      create_table :berserks do |t|
        t.string :name
        t.timestamps
      end
      create_table :padawans do |t|
        t.string  :name
        t.integer :master_id
        t.string  :master_type
        t.timestamps
      end
    end

    def self.init
      raise "configuration.application_name must not be nil" if @configuration.application_name.nil?
      @logger          = @configuration.logger
      @event_factory   = Flu::EventFactory.new(@configuration)
      @event_publisher = create_event_publisher(@configuration)
      extend_models_and_controllers
    end

    class Dynasty < ActiveRecord::Base
      has_many :ninjas, dependent: :destroy
    end

    class Ninja < ActiveRecord::Base
      track_entity_changes user_metadata: {
        create: lambda {
          {
            dynastyName: dynasty.name
          }
        },
        update: lambda {
          {
            dynastyYear: dynasty.year
          }
        },

      }, ignored_model_changes: ["weight"]

      belongs_to :dynasty
      has_one :padawan, as: :master, dependent: :nullify
    end

    class Berserk < ActiveRecord::Base
      track_entity_changes
      has_one :padawan, as: :master, dependent: :nullify
    end

    class Padawan < ActiveRecord::Base
      track_entity_changes emitter: lambda { " star-wars application " }
      belongs_to :master, polymorphic: true
    end
  end

  after(:each) do
    @event_publisher.clear
    ActiveRecord::Base.connection.execute("DELETE FROM ninjas")
    ActiveRecord::Base.connection.execute("DELETE FROM dynasties")
  end
end

RSpec.configure do |rspec|
  rspec.include_context "active records defined", include_shared: true
end
