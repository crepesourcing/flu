require_relative "flu/version"
require_relative "flu/event"
require_relative "flu/event_factory"
require_relative "flu/queue_repository"
require_relative "flu/configuration"
require_relative "flu/core_ext"
require_relative "flu/event_publisher"
require_relative "flu/railtie" if defined?(Rails)

module Flu
  def self.configure
    yield @configuration ||= Flu::Configuration.new
  end

  def self.config
    @configuration
  end

  def self.logger
    @logger
  end

  def self.event_factory
    @event_factory
  end

  def self.event_publisher
    @event_publisher
  end

  def self.init
    @logger          = @configuration.logger || Rails.logger
    @event_publisher = Flu::EventPublisher.new(@logger, @configuration)
    @event_factory   = Flu::EventFactory.new(@logger, @configuration)

    if @configuration.development_environments.include?(Rails.env)
      Flu::CoreExt.extend_active_record_base_dummy
      Flu::CoreExt.extend_active_controller_base_dummy
    else
      Flu::CoreExt.extend_active_record_base(@event_factory, @event_publisher)
      Flu::CoreExt.extend_active_controller_base(@event_factory, @event_publisher, @logger)
    end
  end

  def self.start
    @event_publisher.connect if config.auto_connect_to_exchange
  end

  configure do |config|
    config.development_environments       = []
    config.tracked_session_keys           = []
    config.rejected_user_agents           = []
    config.logger                         = nil
    config.rabbitmq_host                  = "localhost"
    config.rabbitmq_port                  = "5672"
    config.rabbitmq_management_port       = "15672"
    config.rabbitmq_user                  = ""
    config.rabbitmq_password              = ""
    config.rabbitmq_exchange_name         = "events"
    config.rabbitmq_exchange_durable      = true
    config.auto_connect_to_exchange       = true
    config.default_ignored_model_changes  = [:password, :password_confirmation, :created_at, :updated_at]
    config.default_ignored_request_params = [:password, :password_confirmation, :controller, :action]
  end
end
