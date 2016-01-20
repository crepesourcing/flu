module Flu
  class Base
    def initialize(logger, world, configuration)
      @logger         = logger
      @configuration  = configuration
      @world          = world
    end

    def track_action(action)
      action            = sanitize(action)
      event             = {}
      event[:origin]    = Rails.application.class.parent_name.to_s.camelize
      event[:name]      = "#{action[:controller_name]} #{action[:action_name]}"
      event[:payload]   = deep_camelize(action)
      event[:timestamp] = Time.now.utc
      @logger.debug("Track action: " + JSON.pretty_generate(event))
      @world.spread(event)
    end

    def track_change(change)
      return if change[:data].empty?
      change                    = sanitize(change)
      event                     = {}
      event[:origin]            = Rails.application.class.parent_name.to_s.camelize
      event[:name]              = "#{change[:model_name]} #{change[:action_name]}"
      event[:payload]           = deep_camelize(change)
      event[:timestamp]         = Time.now.utc
      @logger.debug("Track change: " + JSON.pretty_generate(event))
      @world.spread(event)
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
