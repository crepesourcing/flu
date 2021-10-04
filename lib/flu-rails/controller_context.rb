module Flu
  class ControllerContext
    def self.flu_tracker_request_id=(value)
      Thread.current[:flu_tracker_request_id] = value
    end

    def self.flu_tracker_request_id
      Thread.current[:flu_tracker_request_id]
    end

    def self.flu_tracker_request_entity_metadata=(value)
      Thread.current[:flu_tracker_request_id] = value
    end

    def self.flu_tracker_request_entity_metadata
      Thread.current[:flu_tracker_request_id]
    end
  end
end