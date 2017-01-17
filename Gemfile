source 'https://rubygems.org'

ruby '2.3.3'
gem 'rails', '~> 4.2.7'

gem 'active_model_serializers', '~> 0.9.3'              # 0.10 is not backward compatible with 0.9
gem 'aescrypt'
gem 'american_date'
gem 'bootstrap-sass'
gem 'cancancan'
gem "carmen-rails"
gem "carrierwave"
gem 'carrierwave-mimetype-fu'
gem 'chosen-rails'
gem 'chronic'
gem 'coffee-rails'
gem 'compass-rails'
gem 'daemons'
gem 'datetimepicker-rails', git: 'git://github.com/zpaulovics/datetimepicker-rails', tag: 'v1.0.0'
gem "devise"
gem 'dimensions'
gem 'enumerize'
gem 'faker'
gem 'faraday_middleware-aws-signers-v4'
gem 'figaro'
gem "fog"
gem 'forecast_io'
gem 'geocoder'
gem "google-api-client"
gem "haml-rails"
gem 'health_check'
gem 'hpricot'
gem 'htmlcompressor'
gem 'httparty'
gem 'icalendar'
gem 'ice_cube'
gem 'jbuilder'
gem 'joiner'
gem 'jquery-datatables-rails'
gem 'jquery-rails'
gem "jquery-turbolinks"
gem 'kaminari'
gem "legato"
gem 'lograge'
gem 'mail'
gem 'mini_magick'
gem 'net-http-persistent'
gem 'newrelic_rpm'
gem "nokogiri"
gem 'oauth2'
gem 'open-uri-s3'
gem 'paranoia'
gem "pg"
gem 'postmark-rails'
gem 'puma'
gem 'rack-cors', require: "rack/cors"
gem 'rails-deprecated_sanitizer', '~> 1.0.3' # need to keep older sanitize with Rails 4.2 upgrde
gem 'ransack'
gem "rdf"
gem 'redis-rails'
gem 'rinku'
gem "rolify"
gem "rubypress"
gem "rubyzip"
gem 'sanitize'
gem 'sass-rails'
gem 'searchkick'
gem 'sidekiq'
gem 'sidekiq-scheduler'
gem 'sidekiq-unique-jobs'
gem "simple_form"
gem 'sinatra', require: false # for sidekiq/web
gem 'sparql-client'
gem 'sshkit'
gem 'summernote-rails'
gem 'thor', '0.19.1'                                # Later versions cause warnings
gem "turbolinks"
gem 'typhoeus'
gem 'uglifier'
gem 'unf'

group :development, :test do
  gem "factory_girl_rails"
  gem 'guard-bundler', require:false
  gem 'guard-rspec', require:false
  gem 'guard-zeus', require: false
  gem 'rspec'
  gem 'rspec-activejob'
  gem "rspec-rails"
end

group :test do
  gem "database_cleaner"
  gem 'rspec_boolean'
  gem 'rspec_junit_formatter'               # this is for circleci to properly read & format our test results
  gem 'shoulda-matchers'
  gem 'simplecov'
  gem "test_after_commit"
  gem "timecop"
  gem "vcr"
  gem "webmock"
end

group :development do
  gem "annotate"
  gem "better_errors"
  gem "binding_of_caller"
  gem "letter_opener"
  gem "quiet_assets"
  gem "yard"
end

group :pry do
  gem 'byebug'
  gem "pry"
  gem "pry-rails"
end
