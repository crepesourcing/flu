module RailsHelper
  def stub_rails
    stub_const 'Rails', Class.new
    allow(Rails).to receive_message_chain("application.class.parent_name.to_s.camelize") { "flu_test" }
    allow(Rails).to receive("env") { "test" }
    Flu.load_configuration
  end
end
