require_relative "flu/version"
require_relative "flu/base"
require_relative "flu/configuration"
require_relative "flu/core_ext"
require_relative "flu/world"
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

  def self.world
    @world
  end

  def self.init
    @logger = @configuration.logger || Rails.logger
    @world  = Flu::World.new(@logger, @configuration)
    flu     = Flu::Base.new(@logger, @world, @configuration)

    if @configuration.development_environments.include?(Rails.env)
      Flu::CoreExt.extend_active_record_base_dummy
      Flu::CoreExt.extend_active_controller_base_dummy
    else
      Flu::CoreExt.extend_active_record_base(flu)
      Flu::CoreExt.extend_active_controller_base(flu, @logger)
    end
  end

  configure do |config|
    config.development_environments   = []
    config.tracked_session_keys       = []
    config.rejected_user_agents       = []
    config.logger                     = nil
    config.controller_additional_data = nil
    config.rabbitmq_host              = "localhost"
    config.rabbitmq_port              = "5672"
    config.rabbitmq_user              = ""
    config.rabbitmq_password          = ""
    config.rabbitmq_exchange_name     = "events"
    config.rabbitmq_exchange_type     = "fanout"
    config.rabbitmq_exchange_durable  = true
  end
end
