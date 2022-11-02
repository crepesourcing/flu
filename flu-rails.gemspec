# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "flu-rails/version"

Gem::Specification.new do |spec|
  spec.name          = "flu-rails"
  spec.version       = Flu::VERSION
  spec.authors       = ["Lo\xC3\xAFc Vigneron, Lorent Lempereur, Thibault Poncelet"]
  spec.email         = ["info@spin42.com", "info@commuty.net"]
  spec.summary       = "Track your application events and publish them to RabbitMQ."
  spec.description   = "To be defined :)"
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler",                     "~> 2", ">=2.1.4"
  spec.add_development_dependency "activerecord",                ">=6.0.0"
  spec.add_development_dependency "actionpack",                  ">=6.0.0"
  spec.add_development_dependency "sqlite3",                     "1.5.3"
  spec.add_development_dependency "rspec",                       "3.12.0"
  spec.add_development_dependency "byebug",                      "11.1.3"
  spec.add_dependency             "bunny",                       "~> 2.19", ">=2.19.0"
  spec.add_dependency             "rabbitmq_http_api_client",    "~> 2.1", ">=2.0.0"
  spec.add_dependency             "activesupport",               ">=6.0.0"
end
