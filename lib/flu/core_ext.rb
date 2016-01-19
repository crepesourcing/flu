module Flu
  class CoreExt
    ACTION_UID_METHOD_NAME        = "flu_tracker_action_uid"
    REJECTED_ACTION_PARAMS_KEYS   = [:controller, :action]

    def self.extend_active_record_base_dummy
      ActiveRecord::Base.class_eval { define_singleton_method(:track_change) { ; } }
    end

    def self.extend_active_record_base(flu)
      ActiveRecord::Base.class_eval do
        define_singleton_method(:track_change) do |options = {}|
          after_create  { track_change(flu, :create, changes) }
          after_update  { track_change(flu, :update, changes) }
          after_destroy { track_change(flu, :destroy, "id": [id, nil]) }
        end

        def track_change(flu, action_name, changes)
          change               = {}
          change[:model_name]  = self.class.name.underscore
          change[:data]        = changes.except(:created_at, :updated_at)
          change[:action_uid]  = send(ACTION_UID_METHOD_NAME) if respond_to?(ACTION_UID_METHOD_NAME)
          change[:action_name] = action_name
          flu.track_change(change)
        end
      end
    end

    def self.extend_active_controller_base_dummy
      ActionController::Base.class_eval do
        define_singleton_method(:track_action) { ; }
      end
    end

    def self.extend_active_controller_base(flu, logger)
      ActionController::Base.class_eval do
        define_singleton_method(:track_action) do |options = {}|
          before_action(options) { define_action_uid }
          prepend_after_action(options) { track_action(flu, logger) }
          after_action(options) { remove_action_uid }

          def define_action_uid
            action_uid       = SecureRandom.uuid
            @flu_action_uid  = action_uid
            ActiveRecord::Base.send(:define_method, ACTION_UID_METHOD_NAME, proc { action_uid })
          end

          def remove_action_uid
            ActiveRecord::Base.send(:remove_method, ACTION_UID_METHOD_NAME)
          end

          def track_action(flu, logger)
            if Flu::CoreExt.rejected_origin?(request)
              logger.warn "Origin user agent rejected: #{request.user_agent}"
              return
            end
            additional_data_block      = Flu.config.controller_additional_data
            action                     = {}
            action[:cookies_data]      = Flu::CoreExt.extract_tracked_session_keys(session)
            if additional_data_block
              action[:additional_data] = self.instance_exec(&additional_data_block)
            end
            action[:controller_name]   = params[:controller]
            action[:action_name]       = params[:action]
            action[:response_code]     = response.status
            action[:data]              = params.reject do |key, _value|
              REJECTED_ACTION_PARAMS_KEYS.include?(key)
            end
            action[:data][:user_agent] = request.user_agent
            action[:action_uid]        = @flu_action_uid
            flu.track_action(action)
          end
        end
      end
    end

    def self.extract_tracked_session_keys(session)
      keys = Flu.config.tracked_session_keys
      keys.each_with_object({}) do |key, hash|
        hash[key] = session[key]
      end
    end

    def self.rejected_origin?(request)
      rejected_user_agents  = Regexp.union(Flu.config.rejected_user_agents)
      user_agent            = request.user_agent
      matching_user_agents  = user_agent.match(rejected_user_agents)
      !matching_user_agents.nil?
    end
  end
end
