module Flu
  class Railtie < Rails::Railtie
    railtie_name :flu

    config.to_prepare do
      Flu.init
      Flu.start
    end

    config.after_initialize do
      Flu.start
    end
  end
end
