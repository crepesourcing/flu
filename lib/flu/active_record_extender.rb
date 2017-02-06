module Flu
  class ActiveRecordExtender
    def self.extend_models(event_factory, event_publisher)
      ActiveRecord::Base.class_eval do
        define_singleton_method(:track_entity_changes) do |options = {}|
          self.flu_is_tracked     = true
          user_metadata_lambda    = options.fetch(:user_metadata, {})
          user_metadata_on_create = user_metadata_lambda[:create]
          user_metadata_on_update = user_metadata_lambda[:update]
          ignored_model_changes   = options.fetch(:ignored_model_changes, []).map(&:to_s)

          after_create   { flu_track_entity_change(:create, changes, user_metadata_lambda[:create], event_factory, ignored_model_changes) }
          after_update   { flu_track_entity_change(:update, changes, user_metadata_lambda[:update], event_factory, ignored_model_changes) }
          after_destroy  { flu_track_entity_change(:destroy, { "id" => [id, nil] }, nil,            event_factory, ignored_model_changes) }
          after_commit   { flu_commit_changes(event_factory, event_publisher) }
          after_rollback { flu_rollback_changes }
        end

        def self.flu_is_tracked=(is_tracked)
          @flu_is_tracked = is_tracked
        end

        def self.flu_is_tracked
          @flu_is_tracked || false
        end

        def self.flu_foreign_keys(&block)
          @flu_foreign_keys ||= yield
        end

        def flu_changes
          @flu_changes ||= []
        end

        def flu_commit_changes(event_factory, event_publisher)
          flu_changes.select do |data|
            !data[:changes].empty?
          end.each do | data |
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

        def flu_track_entity_change(action_name,
                                    changes,
                                    user_metadata_lambda,
                                    event_factory,
                                    ignored_model_changes)
          unless changes.empty?
            foreign_keys = self.class.flu_foreign_keys do
              self.class.reflect_on_all_associations(:belongs_to).map { |association| association.foreign_key }
            end
            request_id   = respond_to?(Flu::CoreExt::REQUEST_ID_METHOD_NAME) ? send(Flu::CoreExt::REQUEST_ID_METHOD_NAME) : nil
            data         = event_factory.create_data_from_entity_changes(action_name,
                                                                         self,
                                                                         request_id,
                                                                         changes,
                                                                         user_metadata_lambda,
                                                                         foreign_keys,
                                                                         ignored_model_changes)
            flu_changes.push(data) unless data.nil?
          end
        end
      end
    end
  end
end
