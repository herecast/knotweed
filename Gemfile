source 'https://rubygems.org'

ruby '2.3.3'
gem 'rails', '~> 5.1.6'

gem 'active_model_serializers', '~> 0.9.3'              # 0.10 is not backward compatible with 0.9
gem 'aescrypt'
gem 'american_date'
gem 'bootstrap-sass'
gem 'cancancan'
gem "carmen-rails"
gem "carrierwave", '~> 1.0'
gem 'carrierwave-mimetype-fu'
gem 'chosen-rails'
gem 'chronic'
gem 'cocoon'
gem 'coffee-rails'
gem 'compass-rails'
gem 'daemons'
gem 'datetimepicker-rails', git: 'git://github.com/zpaulovics/datetimepicker-rails', tag: 'v1.0.0'
gem "devise", '~> 4.5.0'                                # Have not yet tested the next major version
gem 'dimensions'
gem 'enumerize'
gem 'faker'
gem 'faraday_middleware-aws-signers-v4'
gem 'figaro'
gem "fog"
gem 'forecast_io'
gem 'geocoder'
gem "haml-rails"
gem 'health_check', '~> 3.0'
gem 'hpricot'
gem 'htmlcompressor'
gem 'httparty'
gem 'icalendar'
gem 'ice_cube', '0.16.0'
gem 'inky-rb', require: 'inky'                        # DSL for email templates
gem 'intercom', '~> 3.5.21'
gem 'jbuilder'
gem 'joiner'
gem 'jquery-datatables-rails'
gem 'jquery-rails'
gem 'kaminari', '~> 0.15'                             # Have not yet tested the next major version
gem 'lograge'
gem 'mail'
gem 'mailchimp-api', '~> 2.0.6', require: 'mailchimp'
gem 'mini_magick'
gem 'net-http-persistent'
gem 'newrelic_rpm'
gem "nokogiri"
gem 'oauth2'
gem 'open-uri-s3'
gem 'paranoia'
gem "pg", '~> 0.18'
gem 'postmark-rails'
gem 'premailer-rails'                                 # Email asset pipeline
gem 'puma'
gem 'rack-cors', require: "rack/cors"
gem 'rails-deprecated_sanitizer', '~> 1.0.3' # need to keep older sanitize with Rails 4.2 upgrde
gem 'ransack'
gem 'redis-rails'
gem 'rinku', '~> 1.7'                               # Have not yet tested the next major version
gem "rolify"
gem "rubypress"
gem "rubyzip"
gem 'sanitize'
gem 'sass-rails'
gem 'searchkick', '~> 2.3'                          # Have not yet tested the next major version
gem 'sidekiq'
gem 'sidekiq-scheduler'
gem 'sidekiq-unique-jobs'
gem "simple_form"
gem 'sinatra', require: false # for sidekiq/web
gem "slack-notifier", '~> 2.3.1'
gem 'sshkit'
gem 'summernote-rails'
gem 'thor', '0.19.1'                                # Later versions cause warnings
gem "turbolinks", '~> 5.2'
gem 'typhoeus'
gem 'uglifier', '~> 2.4'                            # Have not yet tested the next major version
gem 'unf'

group :development, :test do
  gem "factory_girl_rails", "~> 4.4.0"              # 4.5.0 causes a failure in the test suite
  gem 'guard-bundler', require: false
  gem 'guard', require: false
  gem 'guard-rspec', require: false
  gem 'rspec'
  gem "rspec-rails", '~> 3.7'
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'active_record_query_trace'
  gem 'ruby-prof'
end

group :test do
  gem "database_cleaner"
  gem 'rails-controller-testing'
  gem 'rspec_boolean'
  gem 'rspec-json_expectations'
  gem 'rspec_junit_formatter' # this is for circleci to properly read & format our test results
  gem 'shoulda-matchers'
  gem 'simplecov'
  gem "timecop"
  gem "vcr", '~> 2.9'                               # Have not yet tested the next major version
  gem "webmock"
end

group :development do
  gem "annotate",      '~> 2.7.4'
  gem "coffeelint"
  gem "better_errors", '~> 0.9'                     # Have not yet tested the next major version
  gem "letter_opener"
  gem "yard"
  gem 'rubocop', '~> 0.61.1', require: false
end

group :pry do
  gem 'byebug'
  gem "pry"
  gem "pry-rails"
end
