FROM ruby:2.3
RUN mkdir -p /usr/src/app/lib/flu-rails
WORKDIR /usr/src/app

COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/
COPY flu-rails.gemspec /usr/src/app/
COPY lib/flu-rails/version.rb /usr/src/app/lib/flu-rails/
RUN bundle install
COPY . /usr/src/app
RUN bundle install