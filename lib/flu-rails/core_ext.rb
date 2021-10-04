require_relative "active_record_extender"
require_relative "action_controller_extender"

module Flu
  class CoreExt
    REQUEST_ID_METHOD_NAME              = "flu_tracker_request_id"
    REQUEST_ENTITY_METADATA_METHOD_NAME = "flu_tracker_request_entity_metadata"

    def self.extend_model_classes(event_factory, event_publisher)
      ActiveRecordExtender.extend_models(event_factory, event_publisher)
    end

    def self.extend_controller_classes(event_factory, event_publisher, logger)
      ActionControllerExtender.extend_controllers(event_factory, event_publisher, logger)
    end
  end
end
