require_relative "active_record_extender"
require_relative "application_controller_extender"

module Flu
  class CoreExt
    REQUEST_ID_METHOD_NAME = "flu_tracker_request_id"

    def self.extend_model_classes(event_factory, event_publisher)
      ActiveRecordExtender.extend_models(event_factory, event_publisher)
    end

    def self.extend_controller_classes(event_factory, event_publisher, logger)
      ApplicationControllerExtender.extend_controllers(event_factory, event_publisher, logger)
    end
  end
end
