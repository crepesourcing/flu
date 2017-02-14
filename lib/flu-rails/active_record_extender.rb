module Flu
  class ActiveRecordExtender
    def self.extend_models(event_factory, event_publisher)
      ActiveRecord::Base.class_eval do
        define_singleton_method(:track_entity_changes) do |options = {}|
          self.flu_is_tracked            = true
          self.flu_user_metadata_lambdas = options.fetch(:user_metadata, {})
          self.flu_ignored_model_changes = options.fetch(:ignored_model_changes, []).map(&:to_s)

          after_create   { flu_track_entity_change(:create, changes, event_factory) }
          after_update   { flu_track_entity_change(:update, changes, event_factory) }
          after_destroy  { flu_track_entity_change(:destroy, { "id" => [id, nil] }, event_factory) }
          after_commit   { flu_commit_changes(event_factory, event_publisher) }
          after_rollback { flu_rollback_changes }
        end

        def self.flu_ignored_model_changes=(ignored_model_changes)
          @flu_ignored_model_changes = ignored_model_changes
        end

        def self.flu_ignored_model_changes
          @flu_ignored_model_changes
        end

        def self.flu_user_metadata_lambdas=(user_metadata_lambdas)
          @flu_user_metadata_lambdas = user_metadata_lambdas
        end

        def self.flu_user_metadata_lambdas
          @flu_user_metadata_lambdas
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

        def flu_track_entity_change(action_name, changes, event_factory)
          unless changes.empty?
            foreign_keys = self.class.flu_foreign_keys do
              self.class.reflect_on_all_associations(:belongs_to).map { |association| association.foreign_key }
            end
            request_id = respond_to?(Flu::CoreExt::REQUEST_ID_METHOD_NAME) ? send(Flu::CoreExt::REQUEST_ID_METHOD_NAME) : nil
            data       = event_factory.create_data_from_entity_changes(action_name,
                                                                       self,
                                                                       request_id,
                                                                       changes,
                                                                       self.class.flu_user_metadata_lambdas[action_name],
                                                                       foreign_keys,
                                                                       self.class.flu_ignored_model_changes)
            flu_changes.push(data) unless data.nil?
          end
        end
      end
    end
  end
end
