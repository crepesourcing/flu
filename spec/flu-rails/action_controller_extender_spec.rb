require_relative "../support/action_controller_context"

RSpec.describe Flu::ActionControllerExtender do
  include_context "controllers defined"

  let(:current_user) { OpenStruct.new(id: 14, name: "Michel")}

  context "#extend_controllers" do
    it "track_requests is available on ActionController::Base classes" do
      expect(ActionController::Base.methods).to include :track_requests
    end

    it "track_requests is available on ActionController::API classes" do
      expect(ActionController::API.methods).to include :track_requests
    end

    it "track_requests is not available on non-controller classes" do
      expect(PadawansController.methods).to_not include :track_requests
    end

    it "DynastiesController's requests must not be tracked" do
      expect(DynastiesController.flu_is_tracked).to be false
    end

    it "NinjasController's requests must be tracked" do
      expect(NinjasController.flu_is_tracked).to be true
    end

    it "BerserksController's requests must be tracked" do
      expect(BerserksController.flu_is_tracked).to be false
    end

    let (:dynasties_controller) { DynastiesController.new }
    let (:ninjas_controller)    { NinjasController.new }
    let (:farmers_controller)   { FarmersController.new }

    context "when calling DynastiesController#create" do
      xit "should not emit any event" do
        dynasties_controller.process(:create)
        expect(@event_publisher.events_count).to eq 0
      end
    end

    context "when calling NinjasController#create" do
      context "with no parameters" do
        before(:each) do
          # ninjas_controller.set_request!(ActionDispatch::Request.empty)
          # ninjas_controller.params = ActionController::Parameters.new({})
          ninjas_controller.process(:create)
        end

        xit "should emit a single event" do
          expect(@event_publisher.events_count).to eq 1
        end
      end
    end

    context "when calling farmers_controller#create" do
      context "with no parameters" do
        before(:each) do
          farmers_controller.process(:create)
        end

        xit "should emit a single event" do
          expect(@event_publisher.events_count).to eq 1
        end
      end
    end
  end
end
