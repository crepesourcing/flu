RSpec.describe Flu::Event do

  let(:valid_kinds)    { [:entity_change, :request] }
  let(:valid_emitters) { ["Frontend", "Emitter"] }
  let(:valid_names)    { ["create invoice", "update order", "destroy invoice", "create invoices"] }
  let(:valid_kind)     { valid_kinds.first }
  let(:valid_emitter)  { valid_emitters.first }
  let(:valid_name)     { valid_names.first }
  let(:valid_data)     { valid_names.first }
  let(:uuid)           { SecureRandom.uuid }

  describe "#initialize" do
    context "when uuid is nil" do
      it "should raise an error" do
        expect { Flu::Event.new(nil, valid_emitter, valid_kind, valid_name, {}) }.to raise_error(ArgumentError)
      end
    end

    context "when emitter is nil" do
      it "should raise an error" do
        expect { Flu::Event.new(uuid, nil, valid_kind, valid_name, {}) }.to raise_error(ArgumentError)
      end
    end

    context "when emitter is empty" do
      it "should raise an error" do
        expect { Flu::Event.new(uuid, "", valid_kind, valid_name, {}) }.to raise_error(ArgumentError)
      end
    end

    context "when kind is nil" do
      it "should raise an error" do
        expect { Flu::Event.new(uuid, valid_emitter, nil, valid_name, {}) }.to raise_error(ArgumentError)
      end
    end

    context "when kind is empty" do
      it "should raise an error" do
        expect { Flu::Event.new(uuid, valid_emitter, "", valid_name, {}) }.to raise_error(ArgumentError)
      end
    end

    context "when name is nil" do
      it "should raise an error" do
        expect { Flu::Event.new(uuid, valid_emitter, valid_kind, nil, {}) }.to raise_error(ArgumentError)
      end
    end

    context "when name is empty" do
      it "should raise an error" do
        expect { Flu::Event.new(uuid, valid_emitter, valid_kind, "", {}) }.to raise_error(ArgumentError)
      end
    end

    context "when data is nil" do
      it "sets data to an empty hash" do
        event = Flu::Event.new(uuid, valid_emitter, valid_kind, valid_name, nil)
        expect(event.data).to eq({})
      end
    end

    it "sets status to new by default" do
      event = Flu::Event.new(uuid, valid_emitter, valid_kind, valid_name, {})
      expect(event.status).to be(:new)
    end
  end

  describe "#to_routing_key" do

  end
end
