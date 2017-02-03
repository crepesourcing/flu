# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "flu/version"

Gem::Specification.new do |spec|
  spec.name          = "flu"
  spec.version       = Flu::VERSION
  spec.authors       = ["Lo\xC3\xAFc Vigneron"]
  spec.email         = ["loic@spin42.com"]
  spec.summary       = "Track your application events and publish them to RabbitMQ."
  spec.description   = "To be defined :)"
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler",                     "1.12.5"
  spec.add_development_dependency "activerecord",                "5.0.1"
  spec.add_development_dependency "sqlite3",                     "1.3.13"
  spec.add_dependency             "bunny",                       ">=2.5.0"
  spec.add_dependency             "rabbitmq_http_api_client",    ">=1.6.0"
  spec.add_dependency             "activesupport",               ">=4.2.0"
end
