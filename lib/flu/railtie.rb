module Flu
  class Railtie < Rails::Railtie
    railtie_name :flu

    config.to_prepare do
      Flu.init
    end
  end
end
