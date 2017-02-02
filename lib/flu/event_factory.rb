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
      event = build_event(name, "request", data)
      @logger.debug("Track action: #{JSON.pretty_generate(event)}")
      event
    end

    def build_entity_change_event(data)
      raise "data must have changes" if data[:changes].empty?
      name  = "#{data[:action_name]} #{data[:entity_name]}"
      event = build_event(name, "entity_change", data)
      @logger.debug("Track change: " + JSON.pretty_generate(event))
      event
    end

    def build_event(name, kind, data)
      Event.new(SecureRandom.uuid, @emitter, kind, name, deep_camelize(data))
    end

    def create_data_from_entity_changes(action_name, entity, request_id, changes, user_metadata_lambda, foreign_keys, ignored_model_changes)
      {
        entity_id:     entity.id,
        entity_name:   entity.class.name.underscore,
        request_id:    request_id,
        action_name:   action_name,
        changes:       changes.except(ignored_model_changes).except(@configuration.default_ignored_model_changes),
        user_metadata: user_metadata_lambda ? entity.instance_exec(&user_metadata_lambda) : {},
        associations:  extract_associations_from(entity, foreign_keys)
      }
    end

    def create_data_from_request(request_id, params, request, response, request_start_time, ignored_request_params)
      ap "params"
      ap params
      ap "ignored_request_params"
      ap ignored_request_params
      ap "default_ignored_request_params"
      ap default_ignored_request_params
      {
        request_id:      request_id,
        controller_name: params[:controller],
        action_name:     params[:action],
        path:            request.original_fullpath,
        response_code:   response.status,
        user_agent:      request.user_agent,
        duration:        Time.zone.now - request_start_time,
        params:          params.except(ignored_request_params).except(@configuration.default_ignored_request_params)
      }
    end

    private

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
