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

  spec.add_development_dependency "bundler",                     ">=1.12.5"
  spec.add_development_dependency "activerecord",                ">=6.0.0"
  spec.add_development_dependency "actionpack",                  ">=6.0.0"
  spec.add_development_dependency "sqlite3",                     "1.4.2"
  spec.add_development_dependency "rspec",                       "3.9.0"
  spec.add_development_dependency "byebug",                      "11.1.1"
  spec.add_dependency             "bunny",                       ">=2.14.4"
  spec.add_dependency             "rabbitmq_http_api_client",    ">=1.13.0"
  spec.add_dependency             "activesupport",               ">=6.0.0"
end
