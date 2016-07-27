FROM ruby:2.2.4
RUN apt-get update -qq && apt-get install -y build-essential libmysqlclient-dev nodejs && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /knotweed
WORKDIR /knotweed
ADD Gemfile /knotweed/
ADD Gemfile.lock /knotweed/
RUN bundle install
ADD . /knotweed/
RUN mv /knotweed/config/thinking_sphinx.yml.docker /knotweed/config/thinking_sphinx.yml
RUN mv /knotweed/config/database.yml.docker /knotweed/config/database.yml
RUN RAILS_ENV=production bundle exec rake assets:precompile
