RSpec.describe Flu do

  describe "#init" do
    context "when Rails is loaded" do
      before (:each) do
        stub_rails
        set_environment_to_test
      end

      after (:each) do
        reset_environment
      end

      it "should set application_name from the rails application name" do
        Flu.init
        expect(Flu.config.application_name).to eq "flu_test"
      end
    end

    context "when Rails is not loaded" do
      context "when application_name is not explicitly set" do
        xit "should raise an error" do
          reset_application_name
          expect { Flu.init }.to raise_error(RuntimeError)
        end
      end

      context "when application_name is explicitly set" do
        xit "should set application_name from this value" do
          set_application_name("flu_test")
          Flu.init
          expect(Flu.config.application_name).to eq "flu_test"
        end
      end
    end
  end
end
