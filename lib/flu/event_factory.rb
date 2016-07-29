module Flu
  class EventFactory
    def initialize(logger, configuration)
      @logger        = logger
      @configuration = configuration
      @emitter       = Rails.application.class.parent_name.to_s.camelize
    end

    def build_request_event(data)
      data  = deep_camelize(sanitize(data))
      name  = "request to #{data[:action_name]} #{data[:controller_name]}"
      kind  = "request"
      event = Event.new(@emitter, kind, name, data)

      @logger.debug("Track action: #{JSON.pretty_generate(event)}")
      event
    end

    def build_entity_change_event(data)
      return if data[:changes].empty?

      name  = "#{data[:action_name]} #{data[:entity_name]}"
      kind  = "entity_change"
      event = Event.new(@emitter, kind, name, deep_camelize(sanitize(data)))

      @logger.debug("Track change: " + JSON.pretty_generate(event))
      event
    end

    def sanitize(value)
      case value
      when Array
        value.map { |v| sanitize(v) }
      when Hash
        fitlered_value = {}
        value.each do |k, v|
          unless [:password, :password_confirmation].include?(k.to_sym)
            fitlered_value[k] = sanitize(v)
          end
        end
        fitlered_value
      else
        value
      end
    end

    def deep_camelize(value)
      case value
      when Array
        value.map { |v| deep_camelize v }
      when Hash
        value.keys.each do |k, v = value[k]|
          value.delete k
          value[k.to_s.camelize(:lower)] = deep_camelize v
        end
        value
      else
        value
      end
    end
  end
end
