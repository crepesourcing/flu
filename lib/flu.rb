require "logger"
require "json"
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
    raise "configuration.application_name must not be nil" if @configuration.application_name.nil?
    @logger          = @configuration.logger
    @event_factory   = Flu::EventFactory.new(@configuration)
    @event_publisher = create_event_publisher(@configuration)
    extend_models_and_controllers
  end

  def self.create_event_publisher(configuration)
    if is_testing_environment?
      logger.info("Loading Flu with a dummy event publisher (this will not connect any exchange)")
      require_relative "flu/dummy/event_publisher_dummy"
      Flu::Dummy::EventPublisherDummy.new(@configuration)
    else
      Flu::EventPublisher.new(@configuration)
    end
  end

  def self.is_testing_environment?
    defined?(Rails) && config.development_environments.include?(Rails.env)
  end

  def self.extend_models_and_controllers
    Flu::CoreExt.extend_model_classes(@event_factory, @event_publisher)
    Flu::CoreExt.extend_controller_classes(@event_factory, @event_publisher, @logger)
  end

  def self.start
    @event_publisher.connect if config.auto_connect_to_exchange
  end

  def self.load_configuration
    configure do |config|
      config.development_environments       = []
      config.tracked_session_keys           = []
      config.rejected_user_agents           = []
      config.logger                         = ::Logger.new(STDOUT)
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
      config.application_name               = defined?(Rails) ? Rails.application.class.parent_name.to_s.camelize : nil
    end
  end

  load_configuration
end
