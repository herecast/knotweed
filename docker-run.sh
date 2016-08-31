#!/usr/bin/env bash

bundle exec rake db:migrate
exec bundle exec rails server -e production -b 0.0.0.0 Puma
