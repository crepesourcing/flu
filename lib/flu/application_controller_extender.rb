module Flu
  class ApplicationControllerExtender
    def self.extend_controllers(event_factory, event_publisher, logger)
      ActionController::Base.class_eval do
        define_singleton_method(:track_requests) do |options = {}|
          before_action(options) do
            define_request_id
            @request_start_time = Time.zone.now
          end
          user_metadata_lambda   = options[:user_metadata]
          ignored_request_params = options.fetch(:ignored_model_changes, []).map(&:to_sym)

          prepend_after_action(options) { track_requests(event_factory, event_publisher, user_metadata_lambda, ignored_request_params) }
          after_action(options) { remove_request_id }

          def define_request_id
            request_id      = SecureRandom.uuid
            @flu_request_id = request_id
            ActiveRecord::Base.send(:define_method, Flu::CoreExt::REQUEST_ID_METHOD_NAME, proc { request_id })
          end

          def remove_request_id
            ActiveRecord::Base.send(:remove_method, Flu::CoreExt::REQUEST_ID_METHOD_NAME)
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
