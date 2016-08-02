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
          user_metadata_lambda             = options[:user_metadata] || {}
          self.flu_user_metadata_on_create = user_metadata_lambda[:create]
          self.flu_user_metadata_on_update = user_metadata_lambda[:update]
          self.flu_is_tracked              = true

          after_create   { flu_track_entity_change(:create, changes, user_metadata_lambda[:create], event_factory) }
          after_update   { flu_track_entity_change(:update, changes, user_metadata_lambda[:update], event_factory) }
          after_destroy  { flu_track_entity_change(:destroy, { "id": [id, nil] }, nil, event_factory) }
          after_commit   { flu_commit_changes(event_factory, event_publisher) }
          after_rollback { flu_rollback_changes }
        end

        def self.flu_user_metadata_on_create=(lambda)
          @flu_user_metadata_on_create = lambda
        end

        def self.flu_is_tracked=(is_tracked)
          @flu_is_tracked = is_tracked
        end

        def self.flu_user_metadata_on_update=(lambda)
          @flu_user_metadata_on_update = lambda
        end

        def self.flu_foreign_keys(&block)
          @flu_foreign_keys ||= yield
        end

        def self.flu_is_tracked
          @flu_is_tracked
        end

        def self.flu_user_metadata_on_create
          @flu_user_metadata_on_create
        end

        def self.flu_user_metadata_on_update
          @flu_user_metadata_on_update
        end

        def flu_changes
          @flu_changes ||= []
        end

        def flu_commit_changes(event_factory, event_publisher)
          flu_changes.each do | change |
            event = event_factory.build_entity_change_event(change)
            event_publisher.publish(event)
          end
        end

        def flu_rollback_changes
          @flu_changes = []
        end

        def flu_track_entity_change(action_name, changes, user_metadata_lambda, event_factory)
          foreign_keys = self.class.flu_foreign_keys do
            self.class.reflect_on_all_associations(:belongs_to).map { |association| association.foreign_key }
          end
          request_id   = respond_to?(REQUEST_ID_METHOD_NAME) ? send(REQUEST_ID_METHOD_NAME) : nil
          data         = event_factory.create_data_from_entity_changes(action_name, self, request_id, changes, user_metadata_lambda, foreign_keys)
          flu_changes.push(data)
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
            user_metadata_block = Flu.config.controller_user_metadata
            parameters          = params.reject do |key, _value|
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

            if user_metadata_block
              user_metadata   = instance_exec(&user_metadata_block)
              tracked_request = tracked_request.merge(user_metadata)
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
