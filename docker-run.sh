#!/usr/bin/env bash

mkdir -p /sphinx_shared/{config,db}
mkdir -p /sphinx_shared/db/sphinx
bundle exec rake ts:configure
bundle exec rake db:migrate
exec bundle exec rails server -e production -b 0.0.0.0 Puma
