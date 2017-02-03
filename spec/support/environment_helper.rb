module EnvironmentHelper
  def set_environment_to_test
    Flu.config.development_environments = ["test"]
  end

  def reset_environment
    Flu.config.development_environments = []
  end

  def set_application_name(name)
    Flu.config.application_name = name
  end

  def reset_application_name
    Flu.config.application_name = nil
  end
end
