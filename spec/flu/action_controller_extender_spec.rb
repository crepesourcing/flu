require_relative "../support/action_controller_context"

RSpec.describe Flu::ActionControllerExtender do
  include_context "controllers defined"

  let(:current_user) { OpenStruct.new(id: 14, name: "Michel")}

  context "#extend_controllers" do
    it "DynastiesController's requests must not be tracked" do
      expect(DynastiesController.flu_is_tracked).to be false
    end

    it "NinjasController's requests must be tracked" do
      expect(NinjasController.flu_is_tracked).to be true
    end

    let (:dynasties_controller) { DynastiesController.new }
    let (:ninjas_controller)    { NinjasController.new }

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
  end
end
