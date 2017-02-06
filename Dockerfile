FROM ruby:2.3
RUN mkdir -p /usr/src/app/lib/flu
WORKDIR /usr/src/app

COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/
COPY flu.gemspec /usr/src/app/
COPY lib/flu/version.rb /usr/src/app/lib/flu/
RUN bundle install

COPY . /usr/src/app
RUN bundle install
