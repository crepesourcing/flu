module Flu
  class ActionControllerExtender
    def self.extend_controllers(event_factory, event_publisher, logger)
      all_controller_types.each do |controller_type|
        controller_type.class_eval do
          def self.flu_is_tracked=(is_tracked)
            @flu_is_tracked = is_tracked
          end

          def self.flu_is_tracked
            @flu_is_tracked || false
          end 

          define_singleton_method(:track_requests) do |options = {}|
            self.flu_is_tracked    = true
            user_metadata_lambda   = options[:user_metadata]
            ignored_request_params = options.fetch(:ignored_request_params, []).map(&:to_sym)

            before_action do
              define_request_id
              @request_start_time = Time.zone.now
            end
            prepend_after_action do
              track_requests(event_factory, event_publisher, user_metadata_lambda, ignored_request_params)
            end
            after_action do
              remove_request_id
            end

            def define_request_id
              puts "define_request_id"
              puts inspect
              request_id      = SecureRandom.uuid
              @flu_request_id = request_id
              ActiveRecord::Base.send(:define_method, Flu::CoreExt::REQUEST_ID_METHOD_NAME, proc { request_id })
            end

            def remove_request_id
              puts "remove_request_id"
              puts inspect
              ActiveRecord::Base.send(:remove_method, Flu::CoreExt::REQUEST_ID_METHOD_NAME)
            end

            def rejected_origin?(request)
              rejected_user_agents  = Regexp.union(Flu.config.rejected_user_agents)
              user_agent            = request.user_agent
              matching_user_agents  = user_agent.match(rejected_user_agents)
              !matching_user_agents.nil?
            end

            def track_requests(event_factory, event_publisher, user_metadata_lambda, ignored_request_params)
              if rejected_origin?(request)
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
    end

    private

    def self.all_controller_types
      class_names = ["ActionController::Base", "ActionController::API"]
      class_names.select { |class_name| Object.const_defined?(class_name) }.map(&:constantize)
    end
  end
end
