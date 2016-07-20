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
          additional_data_lambda = options[:additional_data] || {}
          after_create   { flu_track_change(flu, :create, changes, additional_data_lambda[:create]) }
          after_update   { flu_track_change(flu, :update, changes, additional_data_lambda[:update]) }
          after_destroy  { flu_track_change(flu, :destroy, { "id": [id, nil] }, nil) }
          after_commit   { flu_commit_changes(flu) }
          after_rollback { flu_rollback_changes }
        end

        def flu_changes
          @flu_changes ||= []
        end

        def flu_commit_changes(flu)
          flu_changes.each do |change|
            flu.track_change(change)
          end
        end

        def flu_rollback_changes
          @flu_changes = []
        end

        def flu_track_change(flu, action_name, changes, additional_data_lambda)
          change                = {}
          change[:model_name]   = self.class.name.underscore
          change[:model_id]     = id
          change[:changes]      = changes.except(:created_at, :updated_at)
          change[:action_uid]   = send(ACTION_UID_METHOD_NAME) if respond_to?(ACTION_UID_METHOD_NAME)
          change[:action_name]  = action_name

          if additional_data_lambda
            additional_data            = instance_exec(&additional_data_lambda)
            formatted_additionnal_data = {}
            additional_data.each do |key, value|
              if value.has_key?(:old) && value.has_key?(:new)
                formatted_additionnal_data[key] = [value[:old], value[:new]] if value[:old] != value[:new]
              else
                raise "The additional data format should be { old: old_value, new: new_value }"
              end
            end
            change[:changes] = change[:changes].merge(formatted_additionnal_data)
          end
          flu_changes.push change
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
            action[:params]              = params.reject do |key, _value|
              REJECTED_ACTION_PARAMS_KEYS.include?(key)
            end
            action[:user_agent] = request.user_agent
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
