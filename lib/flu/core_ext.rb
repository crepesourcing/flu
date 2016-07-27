module Flu
  class CoreExt
    REQUEST_ID_METHOD_NAME       = "flu_tracker_request_id"
    REJECTED_REQUEST_PARAMS_KEYS = [:controller, :action]

    def self.extend_active_record_base_dummy
      ActiveRecord::Base.class_eval { define_singleton_method(:track_entity_changes) { ; } }
    end

    def self.extend_active_record_base(event_factory, event_publisher)
      ActiveRecord::Base.class_eval do
        define_singleton_method(:track_entity_changes) do |options = {}|
          additional_data_lambda = options[:additional_data] || {}
          after_create   { flu_track_entity_change(:create, changes, additional_data_lambda[:create]) }
          after_update   { flu_track_entity_change(:update, changes, additional_data_lambda[:update]) }
          after_destroy  { flu_track_entity_change(:destroy, { "id": [id, nil] }, nil) }
          after_commit   { flu_commit_changes(event_factory, event_publisher) }
          after_rollback { flu_rollback_changes }
        end

        def flu_changes
          @flu_changes ||= []
        end

        def flu_commit_changes(event_factory, event_publisher)
          flu_changes.each do |change|
            event = event_factory.build_entity_change_event(change)
            event_publisher.publish(event)
          end
        end

        def flu_rollback_changes
          @flu_changes = []
        end

        def flu_track_entity_change(action_name, changes, additional_data_lambda)
          data = {
            entity_id:   id,
            entity_name: self.class.name.underscore,
            request_id:  respond_to?(REQUEST_ID_METHOD_NAME) ? send(REQUEST_ID_METHOD_NAME) : nil,
            action_name: action_name,
            changes:     all_changes_in(changes, additional_data_lambda)
          }
          flu_changes.push(data)
        end

        def all_changes_in(changes, additional_data_lambda)
          all_changes = changes.except(:created_at, :updated_at)

          if additional_data_lambda
            additional_data = instance_exec(&additional_data_lambda)
            additional_data.each do |key, value|
              if value.has_key?(:old) && value.has_key?(:new)
                all_changes[key] = [value[:old], value[:new]] if value[:old] != value[:new]
              else
                raise "The additional data format should be { old: old_value, new: new_value }"
              end
            end
          end
          all_changes
        end
      end
    end

    def self.extend_active_controller_base_dummy
      ActionController::Base.class_eval do
        define_singleton_method(:track_requests) { ; }
      end
    end

    def self.extend_active_controller_base(event_factory, event_publisher, logger)
      ActionController::Base.class_eval do
        define_singleton_method(:track_requests) do |options = {}|
          before_action(options) do
            define_request_id
            @request_start_time = Time.zone.now
          end
          prepend_after_action(options) { track_requests(event_factory, event_publisher) }
          after_action(options) { remove_request_id }

          def define_request_id
            request_id      = SecureRandom.uuid
            @flu_request_id = request_id
            ActiveRecord::Base.send(:define_method, REQUEST_ID_METHOD_NAME, proc { request_id })
          end

          def remove_request_id
            ActiveRecord::Base.send(:remove_method, REQUEST_ID_METHOD_NAME)
          end

          def track_requests(event_factory, event_publisher)
            if Flu::CoreExt.rejected_origin?(request)
              logger.warn "Origin user agent rejected: #{request.user_agent}"
              return
            end
            additional_data_block    = Flu.config.controller_additional_data
            parameters = params.reject do |key, _value|
              REJECTED_REQUEST_PARAMS_KEYS.include?(key)
            end

            tracked_request = {
              request_id:       @flu_request_id,
              controller_name:  params[:controller],
              action_name:      params[:action],
              path:             request.original_fullpath,
              response_code:    response.status,
              user_agent:       request.user_agent,
              duration:         Time.zone.now - @request_start_time,
              params:           parameters
            }

            if additional_data_block
              additional_data = instance_exec(&additional_data_block)
              tracked_request = tracked_request.merge(additional_data)
            end

            event = event_factory.build_request_event(tracked_request)
            event_publisher.publish(event)
          end
        end
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
