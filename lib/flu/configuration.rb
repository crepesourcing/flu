module Flu
  class Configuration
    include ActiveSupport::Configurable
    config_accessor :development_environments
    config_accessor :tracked_session_keys
    config_accessor :rejected_user_agents
    config_accessor :logger
    config_accessor :controller_additional_data
    config_accessor :rabbitmq_host
    config_accessor :rabbitmq_port
    config_accessor :rabbitmq_user
    config_accessor :rabbitmq_password
    config_accessor :rabbitmq_exchange_name
    config_accessor :rabbitmq_exchange_durable
    config_accessor :auto_connect_to_exchange
  end
end
