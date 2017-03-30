RSpec.describe Flu::EventFactory do
  let (:application_name) { "flu_test" }
  let (:configuration) {
    configuration                                = Flu::Configuration.new
    configuration.application_name               = application_name
    configuration.logger                         = Logger.new(STDOUT)
    configuration.default_ignored_model_changes  = [:a, :b]
    configuration.default_ignored_request_params = [:c, :d]
    configuration
  }
  let (:factory) {
    Flu::EventFactory.new(configuration)
  }

  describe "#initialize" do
    context "when default_ignored_model_changes contains symbols" do
      it "should convert them into symbols" do
        expect(factory.instance_variable_get(:@default_ignored_model_changes)).to eq ["a", "b"]
      end
    end
  end

  describe "#build_entity_change_event" do
    let(:data) {
      {
        action_name: "create",
        entity_name: "invoice",
        changes: changes
      }
    }
    let(:valid_changes) {
      {
        "month" => ["december", "november"],
        "price" => [4, 6],
        "id"    => [nil, 1]
      }
    }

    context "when data is nil" do
      it "should raise an error" do
        expect { factory.build_entity_change_event(nil) }.to raise_error(ArgumentError)
      end
    end
    context "when data does not have any key 'changes'" do
      let (:no_changes) {
        {not_changes: {a: "test"}}
      }
      it "should raise an error" do
        expect { factory.build_entity_change_event(no_changes) }.to raise_error(ArgumentError)
      end
    end
    context "when data does not have any changes" do
      let (:changes) {
        {changes: {}}
      }
      it "should raise an error" do
        data = { changes: {}}
        expect { factory.build_entity_change_event(data) }.to raise_error(ArgumentError)
      end
    end
    context "when data does not have any action_name" do
      let (:changes) { valid_changes }
      it "should raise an error" do
        expect { factory.build_entity_change_event(data.except(:action_name)) }.to raise_error(ArgumentError)
      end
    end
    context "when data does not any entity_name" do
      let (:changes) { valid_changes }
      it "should raise an error" do
        expect { factory.build_entity_change_event(data.except(:entity_name)) }.to raise_error(ArgumentError)
      end
    end
    context "when data contains changes with underscored keys" do
      let (:changes) {
        {
          changes: {
            "test_name"        => [1, 2],
            "another_key_test" => [3, 4]
          }
        }
      }
      it "should camelize them" do
        event = factory.build_entity_change_event(data)
        expected_data = {
          "actionName" => "create",
          "entityName" => "invoice",
          "changes" => {
            "changes"=> {
              "testName"=>[1, 2],
              "anotherKeyTest"=>[3, 4]
            }
          }
        }
        expect(event.data).to eq expected_data
      end
    end
    context "when data are valid" do
      let (:changes) { valid_changes }
      before(:each) do
        @event = factory.build_entity_change_event(data)
      end
      it "should set a valid name" do
        expect(@event.name).to eq "create invoice"
      end
      it "should set a valid kind" do
        expect(@event.kind).to eq :entity_change
      end
      it "should set the emitter to the application name" do
        expect(@event.emitter).to eq application_name
      end
      it "should set a valid id" do
        expect(@event.id).not_to be_nil
      end
    end
    context "when data has invalid characters" do
      let(:changes_with_invalid_characters) do
        {
          "month" => ["december", "\u0000novem\u0000be\u0000r"],
          "price" => [4, 6],
          "id"    => [nil, 1]
        }
      end
      let(:changes) { changes_with_invalid_characters }
      before(:each) do
        @event = factory.build_entity_change_event(data)
      end

      it "removes the invalid character" do
        expect(@event.data.dig("changes", "month")[1]).to eq("november")
      end
    end
  end

  describe "#build_request_event" do
    let(:data) {
      {
        action_name:     "create",
        controller_name: "orders",
        controller:      "/internal/orders/orders",
        path:            "/api/orders",
        params:          {
                           "price": 10,
                           "user_id": 1000
                         },
        default:         {format: "json"},
        response_code:   200,
        duration:        80
      }
    }

    context "when data is nil" do
      it "should raise an error" do
        expect { factory.build_request_event(nil) }.to raise_error(ArgumentError)
      end
    end
    context "when data does not have any changes" do
      let (:changes) {
        {changes: {}}
      }
      it "should raise an error" do
        data = { changes: {}}
        expect { factory.build_request_event(data) }.to raise_error(ArgumentError)
      end
    end
    context "when data does not have any action_name" do
      let (:changes) { valid_changes }
      it "should raise an error" do
        expect { factory.build_request_event(data.except(:action_name)) }.to raise_error(ArgumentError)
      end
    end
    context "when data does not any controller_name" do
      let (:changes) { valid_changes }
      it "should raise an error" do
        expect { factory.build_request_event(data.except(:controller_name)) }.to raise_error(ArgumentError)
      end
    end
    context "when data contains underscored keys" do
      let(:underscored_data) {
        {
          action_name:     "create",
          controller_name: "orders",
          params:          {
                             "price_value": 10,
                             "user_id": 1000
                           }
        }
      }
      it "should camelize them" do
        event = factory.build_request_event(underscored_data)
        expected_data = {
          "actionName"     => "create",
          "controllerName" => "orders",
          "params" => {
            "priceValue" => 10,
            "userId" => 1000
          }
        }
        expect(event.data).to eq expected_data
      end
    end


    context "when data has invalid characters" do
      let(:data_with_invalid_characters) do
        {
          action_name:     "create",
          controller_name: "orders",
          params:          {
                             "price_value": 10,
                             "user": "User3 1\u0000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\u0000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
                           }
        }
      end
      let(:data) { data_with_invalid_characters }
      before(:each) do
        @event = factory.build_request_event(data)
      end

      it "removes the invalid character" do
        p @event.data
        expect(@event.data.dig("params", "user")).to eq("User3 1aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
      end
    end

    context "when data are valid" do
      it "should set a valid name" do
        event = factory.build_request_event(data)
        expect(event.name).to eq "request to create orders"
      end
      it "should set a valid kind" do
        event = factory.build_request_event(data)
        expect(event.kind).to eq :request
      end
      it "should set the emitter to the application name" do
        event = factory.build_request_event(data)
        expect(event.emitter).to eq application_name
      end
      it "should set a valid id" do
        event = factory.build_request_event(data)
        expect(event.id).not_to be_nil
      end
    end
  end


  ## TODO test ignored fields and params

end



