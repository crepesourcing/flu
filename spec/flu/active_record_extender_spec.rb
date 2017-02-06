require_relative "../support/active_record_context"

RSpec.describe Flu::ActiveRecordExtender do
  include_context "active records defined"

  let(:dynasty) { Dynasty.new(name: "Japan", year: 1300) }

  def fetch_event_for_new_ninja
    @event_publisher.fetch_events("new.ninja_app.entity_change.create ninja").first
  end

  def fetch_event_for_updated_ninja
    @event_publisher.fetch_events("new.ninja_app.entity_change.update ninja").first
  end

  def fetch_event_for_destroyed_ninja
    @event_publisher.fetch_events("new.ninja_app.entity_change.destroy ninja").first
  end

  context "#extend_models" do

    it "Dynasty must not be tracked" do
      expect(Dynasty.flu_is_tracked).to be false
    end

    it "Ninja must be tracked" do
      expect(Ninja.flu_is_tracked).to be true
    end

    context "when saving a dynasty" do
      it "should not emit any event" do
        dynasty.save!
        expect(@event_publisher.events_count).to eq 0
      end
    end

    context "when saving a ninja" do
      let (:ninja) {
        Ninja.new(dynasty: dynasty, name: "Jean Paul", color: :black, height: 160, weight: 60)
      }

      before(:each) do
        ninja.save!
      end

      it "should emit a single event" do
        expect(@event_publisher.events_count).to eq 1
      end

      it "should emit a valid event id" do
        event = fetch_event_for_new_ninja
        expect(event.id).to_not be_nil
      end

      it "should emit a valid event name" do
        event = fetch_event_for_new_ninja
        expect(event.name).to eq "create ninja"
      end

      it "should emit a valid emitter" do
        event = fetch_event_for_new_ninja
        expect(event.emitter).to eq "ninja_app"
      end

      it "should emit a valid timestamp" do
        event = fetch_event_for_new_ninja
        expect(event.timestamp).to_not be_nil
      end

      it "should emit a valid kind" do
        event = fetch_event_for_new_ninja
        expect(event.kind).to eq :entity_change
      end

      it "should emit a valid status" do
        event = fetch_event_for_new_ninja
        expect(event.status).to eq :new
      end

      it "should emit valid changes" do
        event = fetch_event_for_new_ninja
        expected_data = {
          "id" => [nil, ninja.id],
          "name" => [nil, ninja.name],
          "dynastyId" => [nil, dynasty.id],
          "color" => [nil, ninja.color],
          "height" => [nil, ninja.height]
        }
        expect(event.data["changes"]).to eq expected_data
      end

      it "should emit a valid data -> entity id" do
        event = fetch_event_for_new_ninja
        expect(event.data["entityId"]).to eq ninja.id
      end

      it "should emit a valid data -> entity name" do
        event = fetch_event_for_new_ninja
        expect(event.data["entityName"]).to eq "ninja"
      end

      it "should emit a nil data -> request Id" do
        event = fetch_event_for_new_ninja
        expect(event.data["requestId"]).to be_nil
      end

      it "should emit a valid data -> action name" do
        event = fetch_event_for_new_ninja
        expect(event.data["actionName"]).to eq :create
      end

      it "should emit a valid data -> action name" do
        event = fetch_event_for_new_ninja
        expect(event.data["actionName"]).to eq :create
      end

      it "should ignore timestamps (default 'ignore')" do
        event = fetch_event_for_new_ninja
        expect(event.data["changes"].has_key?("updatedAt")).to be false
        expect(event.data["changes"].has_key?("createdAt")).to be false
      end

      it "should ignore timestamps (by_class 'ignore')" do
        event = fetch_event_for_new_ninja
        expect(event.data["changes"].has_key?("weight")).to be false
      end

      it "should emit valid associations" do
        event = fetch_event_for_new_ninja
        expected_associations = {
          "dynastyId" => ninja.dynasty.id
        }
        expect(event.data["associations"]).to eq expected_associations
      end

      it "should emit valid userMetadata" do
        event = fetch_event_for_new_ninja
        expected_metadata = {
          "dynastyName" => ninja.dynasty.name
        }
        expect(event.data["userMetadata"]).to eq expected_metadata
      end

      context "when loading it again" do
        let(:reloaded_ninja) { Ninja.find(ninja.id) }
        before(:each) do
          @event_publisher.clear
        end

        context "when doing nothing with the ninja and saving it" do
          it "should not emit any event" do
            reloaded_ninja.save!
            expect(@event_publisher.events_count).to eq 0
          end
        end

        context "when updating a single ignored field and saving it" do
          it "should not emit any event" do
            reloaded_ninja.weight = 100
            reloaded_ninja.save!
            expect(@event_publisher.events_count).to eq 0
          end
        end

        context "when updating some attributes and saving it" do
          before(:each) do
            reloaded_ninja.color = :purple
            reloaded_ninja.save!
          end

          it "should emit a single event" do
            expect(@event_publisher.events_count).to eq 1
          end

          it "should emit with status new" do
            event = fetch_event_for_updated_ninja
            expect(event.status).to eq :new
          end

          it "should emit with the single change in it" do
            event = fetch_event_for_updated_ninja
            expected_data = {
              "color" => [ninja.color, reloaded_ninja.color]
            }
            expect(event.data["changes"]).to eq expected_data
          end

          it "should emit a valid data -> entity id" do
            event = fetch_event_for_updated_ninja
            expect(event.data["entityId"]).to eq reloaded_ninja.id
          end

          it "should emit a valid data -> entity name" do
            event = fetch_event_for_updated_ninja
            expect(event.data["entityName"]).to eq "ninja"
          end

          it "should emit a nil data -> request Id" do
            event = fetch_event_for_updated_ninja
            expect(event.data["requestId"]).to be_nil
          end

          it "should emit a valid data -> action name" do
            event = fetch_event_for_updated_ninja
            expect(event.data["actionName"]).to eq :update
          end

          it "should ignore timestamps (default 'ignore')" do
            event = fetch_event_for_updated_ninja
            expect(event.data["changes"].has_key?("updatedAt")).to be false
            expect(event.data["changes"].has_key?("createdAt")).to be false
          end

          it "should ignore timestamps (by_class 'ignore')" do
            event = fetch_event_for_updated_ninja
            expect(event.data["changes"].has_key?("weight")).to be false
          end

          it "should emit valid associations" do
            event = fetch_event_for_updated_ninja
            expected_associations = {
              "dynastyId" => reloaded_ninja.dynasty.id
            }
            expect(event.data["associations"]).to eq expected_associations
          end

          it "should emit valid userMetadata" do
            event = fetch_event_for_updated_ninja
            expected_metadata = {
              "dynastyYear" => reloaded_ninja.dynasty.year
            }
            expect(event.data["userMetadata"]).to eq expected_metadata
          end
        end

        context "when deleting it" do
          before(:each) do
            @event_publisher.clear
            reloaded_ninja.destroy!
          end

          it "should emit a single event" do
            expect(@event_publisher.events_count).to eq 1
          end

          it "should emit a valid entityId" do
            event = fetch_event_for_destroyed_ninja
            expect(event.data["entityId"]).to eq reloaded_ninja.id
          end

          it "should emit a valid data -> entity name" do
            event = fetch_event_for_destroyed_ninja
            expect(event.data["entityName"]).to eq "ninja"
          end

          it "should emit a nil data -> request Id" do
            event = fetch_event_for_destroyed_ninja
            expect(event.data["requestId"]).to be_nil
          end

          it "should emit a valid data -> action name" do
            event = fetch_event_for_destroyed_ninja
            expect(event.data["actionName"]).to eq :destroy
          end

          it "should emit with its id only as change" do
            event = fetch_event_for_destroyed_ninja
            expected_data = {
              "id" => [reloaded_ninja.id, nil]
            }
            expect(event.data["changes"]).to eq expected_data
          end

          it "should emit valid associations" do
            event = fetch_event_for_destroyed_ninja
            expected_associations = {
              "dynastyId" => reloaded_ninja.dynasty.id
            }
            expect(event.data["associations"]).to eq expected_associations
          end

          it "should emit an empty userMetadata" do
            event = fetch_event_for_destroyed_ninja
            expect(event.data["userMetadata"]).to be_empty
          end
        end
      end
    end

    context "when saving three ninjas" do
      let (:ninja1) {
        Ninja.new(dynasty: dynasty, name: "Jean Paul", color: :black, height: 160, weight: 60)
      }
      let (:ninja2) {
        Ninja.new(dynasty: dynasty, name: "Henri", color: :yellow, height: 150, weight: 75)
      }
      let (:ninja3) {
        Ninja.new(dynasty: dynasty, name: "Michel", color: :white, height: 200, weight: 80)
      }
      it "should emit 3 events" do
        ninja1.save!
        ninja2.save!
        ninja3.save!
        expect(@event_publisher.events_count).to eq 3
        expect(@event_publisher.fetch_events("new.ninja_app.entity_change.create ninja").size).to eq 3
      end
    end
  end
end
