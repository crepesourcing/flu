module Flu
  class CoreExt
    REQUEST_ID_METHOD_NAME = "flu_tracker_request_id"

    def self.extend_active_record_base_dummy
      ActiveRecord::Base.class_eval do
        define_singleton_method(:track_entity_changes) do |options = {}|
        end
      end
    end

    def self.extend_active_record_base(event_factory, event_publisher)
      ActiveRecord::Base.class_eval do
        define_singleton_method(:track_entity_changes) do |options = {}|
          user_metadata_lambda             = options[:user_metadata] || {}
          self.flu_user_metadata_on_create = user_metadata_lambda[:create]
          self.flu_user_metadata_on_update = user_metadata_lambda[:update]
          self.flu_is_tracked              = true
          self.flu_ignored_model_changes   = options[:ignored_model_changes] || []

          after_create   { flu_track_entity_change(:create, changes, user_metadata_lambda[:create], event_factory, flu_ignored_model_changes) }
          after_update   { flu_track_entity_change(:update, changes, user_metadata_lambda[:update], event_factory, flu_ignored_model_changes) }
          after_destroy  { flu_track_entity_change(:destroy, { "id" => [id, nil] }, nil, event_factory, flu_ignored_model_changes) }
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

        def self.flu_ignored_model_changes=(ignored_changes)
          @flu_ignored_model_changes = ignored_changes.map(&:to_s)
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

        def self.flu_ignored_model_changes
          @flu_ignored_model_changes
        end

        def flu_changes
          @flu_changes ||= []
        end

        def flu_commit_changes(event_factory, event_publisher)
          flu_changes.each do | data |
            event = event_factory.build_entity_change_event(data)
            event_publisher.publish(event)
          end
          flu_flush_changes
        end

        def flu_rollback_changes
          flu_flush_changes
        end

        def flu_flush_changes
          flu_changes.clear
        end

        def flu_track_entity_change(action_name, changes, user_metadata_lambda, event_factory, flu_ignored_model_changes)
          return if changes.empty?
          foreign_keys = self.class.flu_foreign_keys do
            self.class.reflect_on_all_associations(:belongs_to).map { |association| association.foreign_key }
          end
          request_id   = respond_to?(REQUEST_ID_METHOD_NAME) ? send(REQUEST_ID_METHOD_NAME) : nil
          data         = event_factory.create_data_from_entity_changes(action_name, self, request_id, changes, user_metadata_lambda, foreign_keys, flu_ignored_model_changes)
          flu_changes.push(data)
        end
      end
    end

    def self.extend_active_controller_base_dummy
      ActionController::Base.class_eval do
        define_singleton_method(:track_requests) do |options = {}|
        end
      end
    end

    def self.extend_active_controller_base(event_factory, event_publisher, logger)
      ActionController::Base.class_eval do
        define_singleton_method(:track_requests) do |options = {}|
          before_action(options) do
            define_request_id
            @request_start_time = Time.zone.now
          end
          user_metadata_lambda   = options[:user_metadata]
          ignored_request_params = options[:ignored_model_changes]&.map(&:to_sym) || []

          prepend_after_action(options) { track_requests(event_factory, event_publisher, user_metadata_lambda, ignored_request_params) }
          after_action(options) { remove_request_id }

          def define_request_id
            request_id      = SecureRandom.uuid
            @flu_request_id = request_id
            ActiveRecord::Base.send(:define_method, REQUEST_ID_METHOD_NAME, proc { request_id })
          end

          def remove_request_id
            ActiveRecord::Base.send(:remove_method, REQUEST_ID_METHOD_NAME)
          end

          def track_requests(event_factory, event_publisher, user_metadata_lambda, ignored_request_params)
            if Flu::CoreExt.rejected_origin?(request)
              logger.warn "Origin user agent rejected: #{request.user_agent}"
            else
              tracked_request                 = event_factory.create_data_from_request(@flu_request_id,
                                                                                       params,
                                                                                       request,
                                                                                       response,
                                                                                       @request_start_time,
                                                                                       ignored_request_params)
              tracked_request[:user_metadata] = instance_exec(&user_metadata_lambda) if user_metadata_lambda
              event                           = event_factory.build_request_event(tracked_request)
              event_publisher.publish(event)
            end
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
