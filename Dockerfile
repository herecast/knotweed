FROM ruby:2.3.3
RUN apt-get update -qq && apt-get install -y build-essential libmysqlclient-dev nodejs imagemagick && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN echo America/New_York > /etc/timezone && dpkg-reconfigure --frontend noninteractive tzdata
RUN mkdir -p /knotweed
WORKDIR /knotweed
ADD Gemfile /knotweed/
ADD Gemfile.lock /knotweed/
RUN bundle install
ADD . /knotweed/
RUN mv /knotweed/config/database.yml.docker /knotweed/config/database.yml
RUN RAILS_ENV=production bundle exec rake assets:precompile