# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2021-11-05

* Add `bunny_options`
* Add `rabbitmq_manage¨ment_scheme`
* MIT License

## [0.4.2]

* Add capability to add request metadata in the entity_change events related to the request
* Upgrade `rabbitmq_http_api_client`to `2.0`, bunny to `2.19`

## [0.4.1]

* Use of `rabbitmq_http_api_client:1.14.0`, which supports `faraday >= 1`

## [0.4.0]

* Drop support of Rails 5
* Upgrade dependencies: `rabbitmq_http_api_client:1.13.0`, `activesupport:>=6.0.0`, `bunny:>=2.14.4`

## [0.3.1]

* Eager load with Zeitwerk when available

## [0.3.0]

* Support for Rails 6+

## [0.2.0]

* Expose `InMemoryEventPublisher` for testing purpose

## [0.1.9]

* `publish_events!` allows to publish programmatically all the events that are stacked on an ActiveRecord

## [0.1.8]

* Events can be published manually according to a transactionnal context

## [0.1.7]

* Support for ActiveRecord >= 5.1

## [0.1.6]

* Allow to use the Event and the EventPublisher in non-rails environment

## [0.1.5]

* Allow to use the EventFactory in non-rails environment

## [0.1.4]

* Prevent events to be published including an invalid Unicode character (such as `\u0000`)

## [0.1.3]

* Support for polymorphic one-to-one associations
* Support for `ActionController:API`