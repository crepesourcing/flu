module Flu
  class EventFactory
    def initialize(logger, configuration)
      @logger        = logger
      @configuration = configuration
      @emitter       = Rails.application.class.parent_name.to_s.camelize
    end

    def build_request_event(data)
      name  = "request to #{data[:action_name]} #{data[:controller_name]}"
      data  = deep_camelize(sanitize(data))
      kind  = "request"
      event = Event.new(SecureRandom.uuid, @emitter, kind, name, data)

      @logger.debug("Track action: #{JSON.pretty_generate(event)}")
      event
    end

    def build_entity_change_event(data)
      return if data[:changes].empty?

      name  = "#{data[:action_name]} #{data[:entity_name]}"
      kind  = "entity_change"
      event = Event.new(SecureRandom.uuid, @emitter, kind, name, deep_camelize(sanitize(data)))

      @logger.debug("Track change: " + JSON.pretty_generate(event))
      event
    end

    def create_data_from_entity_changes(action_name, entity, request_id, changes, user_metadata_lambda, foreign_keys)
      {
        entity_id:     entity.id,
        entity_name:   entity.class.name.underscore,
        request_id:    request_id,
        action_name:   action_name,
        changes:       changes.except(:created_at, :updated_at),
        user_metadata: user_metadata_lambda ? entity.instance_exec(&user_metadata_lambda) : {},
        associations:  extract_associations_from(entity, foreign_keys)
      }
    end

    private

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

    def extract_associations_from(entity, foreign_keys)
      foreign_keys.inject({}) do | associations, foreign_key |
        associations[foreign_key] = entity[foreign_key]
        associations
      end
    end
  end
end
