source 'https://rubygems.org'

ruby '2.3.3'
gem 'rails', '~> 4.2.7'

gem 'active_model_serializers', '~> 0.9.3'              # 0.10 is not backward compatible with 0.9
gem 'aescrypt'
gem 'american_date'
gem 'bootstrap-sass'
gem 'cancancan'
gem "carmen-rails"
gem "carrierwave", '~> 0.9'                            # Have not yet tested the next major version
gem 'carrierwave-mimetype-fu'
gem 'chosen-rails'
gem 'chronic'
gem 'coffee-rails'
gem 'compass-rails'
gem 'daemons'
gem 'datetimepicker-rails', git: 'git://github.com/zpaulovics/datetimepicker-rails', tag: 'v1.0.0'
gem "devise", '~> 3.5'                                # Have not yet tested the next major version
gem 'dimensions'
gem 'enumerize', '~> 0.11'                            # Have not yet tested the next major version
gem 'faker'
gem 'faraday_middleware-aws-signers-v4'
gem 'figaro'
gem "fog"
gem 'forecast_io'
gem 'geocoder'
gem "google-api-client", '~> 0.8.7'                   # 0.9 causes a failure in the test suite
gem "haml-rails"
gem 'health_check', '~> 1.5'                          # Have not yet tested the next major version
gem 'hpricot'
gem 'htmlcompressor'
gem 'httparty'
gem 'icalendar'
gem 'ice_cube'
gem 'jbuilder'
gem 'joiner'
gem 'jquery-datatables-rails'
gem 'jquery-rails', '~> 3.1'                          # Have not yet tested the next major version
gem "jquery-turbolinks"
gem 'kaminari', '~> 0.15'                             # Have not yet tested the next major version
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
gem "rdf", '~> 1.1'                                 # Have not yet tested the next major version
gem 'redis-rails'
gem 'rinku', '~> 1.7'                               # Have not yet tested the next major version
gem "rolify"
gem "rubypress"
gem "rubyzip"
gem 'sanitize'
gem 'sass-rails'
gem 'searchkick', '~> 1.3'                          # Have not yet tested the next major version
gem 'sidekiq'
gem 'sidekiq-scheduler'
gem 'sidekiq-unique-jobs'
gem "simple_form"
gem 'sinatra', require: false # for sidekiq/web
gem 'sparql-client', '~> 1.1'                       # Have not yet tested the next major version
gem 'sshkit'
gem 'summernote-rails'
gem 'thor', '0.19.1'                                # Later versions cause warnings
gem "turbolinks", '~> 2.2'                          # Have not yet tested the next major version
gem 'typhoeus'
gem 'uglifier', '~> 2.4'                            # Have not yet tested the next major version
gem 'unf'

group :development, :test do
  gem "factory_girl_rails", '~> 4.4.0'              # 4.5.0 causes a failure in the test suite
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
  gem "vcr", '~> 2.9'                               # Have not yet tested the next major version
  gem "webmock"
end

group :development do
  gem "annotate"
  gem "better_errors", '~> 0.9'                     # Have not yet tested the next major version
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
