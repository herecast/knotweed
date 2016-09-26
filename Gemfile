source 'https://rubygems.org'

ruby '2.2.4'

gem 'active_model_serializers', '~> 0.9.3'
gem 'aescrypt'
gem 'american_date', '~> 1.1.0'
gem 'bootstrap-sass', '~> 3.3.6'
gem 'cancancan', '~> 1.13.1'
gem "capistrano", "~> 3.5.0"
gem "capistrano-bundler", "~> 1.1.1"
gem 'capistrano-git-submodule-strategy', '~> 0.1.22'
gem "capistrano-rails", "~> 1.1"
gem "capistrano-rvm", '~> 0.1.1'
gem "carmen-rails", '~> 1.0.0'
gem "carrierwave", '~> 0.9.0'
gem 'carrierwave-mimetype-fu', '~> 0.0.2'
gem 'chosen-rails', '~> 1.0.2'
gem 'chronic', '~> 0.10.2'
gem 'coffee-rails', '~> 4.1.1'
gem 'compass-rails', '~> 3.0.2'
gem 'daemons', '~> 1.1.9'
gem 'datetimepicker-rails', git: 'git://github.com/zpaulovics/datetimepicker-rails', tag: 'v1.0.0'
gem 'delayed_job_active_record', '~> 4.0.0'
gem "devise", '~> 3.5.6'
gem 'dimensions', '~> 1.3.0'
gem 'enumerize', '~> 0.11.0'
gem 'faker', '~> 1.6.1'
gem 'figaro', '~> 1.1', '>= 1.1.1'
gem "fog", '~> 1.38.0'
gem 'forecast_io', '~> 2.0.0'
gem 'geocoder', '~> 1.2.4'
gem "google-api-client", '~> 0.7.1'
gem "haml-rails", '~> 0.9.0'
gem 'hpricot', '~> 0.8.6'
gem 'httparty', '~> 0.12.0'
gem 'icalendar', '~> 2.3'
gem 'ice_cube', "~> 0.13.0"
gem 'jbuilder', '~> 2.1.3'
gem 'joiner', '~> 0.3.4'
gem 'jquery-datatables-rails', '~> 3.4.0'
gem 'jquery-rails', '~> 3.1.2'
gem "jquery-turbolinks", '~> 2.1.0'
gem 'kaminari', '~> 0.15.0'
gem "legato", '~> 0.4.0'
gem 'lograge', '~> 0.3.6'
gem 'mail', '~> 2.5.4'
gem 'mixpanel_client', '~> 4.1.1'
gem 'mixpanel-ruby', '~> 1.4.0' # official ruby mixpanel client. later versions need ruby > 2.0
gem "pg", '~> 0.18.4'
gem 'mysql2', '~> 0.3.18'
gem 'mini_magick', '~> 4.5.1'
gem 'net-http-persistent', '~> 2.9'
gem 'newrelic_rpm', '~> 3.13.0.299'
gem "nokogiri", '1.6.1' # allowing a patch upgrade on this
gem 'oauth2', '~> 1.0.0'
gem 'open-uri-s3', '~> 1.5.0'
gem 'postmark-rails', '~> 0.12.0'
gem 'protected_attributes', '~> 1.1.3'
gem 'rails', '~> 4.2.0'
gem 'rails-deprecated_sanitizer', '~> 1.0.3' # need to keep older sanitize with Rails 4.2 upgrde
gem 'ransack', '~> 1.5.1'
gem "rdf", '~> 1.1.6'
gem 'rinku', "~> 1.7.3"
gem "rolify", '~> 5.1.0'
gem "rubypress", '~> 1.1.0'
gem "rubyzip", "~> 1.1.4"
gem 'sanitize', '~> 4.0.1' # ugc sanitizer
gem 'sass-rails', '~> 5.0.4'
gem 'sidekiq', '~> 4.1.2'
gem 'sidekiq-scheduler', '~> 2.0.7'
gem 'sidekiq-unique-jobs', '~> 4.0.17'
gem 'sinatra', require: false # for sidekiq/web
gem "simple_form", '~> 3.2.1'
gem 'sparql-client', '~> 1.1.3'
gem 'sshkit', '~> 1.11.1'
gem 'summernote-rails', '~> 0.8.1'
gem "turbolinks", '~> 2.2.0'
gem 'uglifier', '~> 2.4.0'
gem 'unf', '~> 0.1.3'
gem 'whenever', '~> 0.9.2', :require => false
gem 'puma', '~> 3.4'

group :development, :test do
  gem "factory_girl_rails", "~> 4.4.0"
  gem 'guard-bundler', require:false
  gem 'guard-rspec', require:false
  gem 'guard-zeus', require: false
  gem 'rspec', '~> 3.4'
  gem 'rspec-activejob'
  gem "rspec-rails", '~> 3.4'
end

group :test do
  gem "database_cleaner", "~> 1.5.3"
  gem 'rspec_junit_formatter', '~> 0.2.3' # this is for circleci to properly read & ormat our test results
  gem 'rspec_boolean'
  gem 'simplecov', '~> 0.10.0'
  gem 'shoulda-matchers', '~> 3.1'
  gem "timecop", '~> 0.7.1'
  gem "vcr", '~> 2.9.2'
  gem "webmock", '~> 2.1.0'
  gem "test_after_commit", "~> 1.1.0"
end

group :development do
  gem "annotate", '~> 2.6.5'
  gem "better_errors", '~> 0.9.0'
  gem "binding_of_caller", '~> 0.7.2'
  gem "letter_opener"
  gem "yard", '~> 0.8.7.6'
  gem "quiet_assets", "~> 1.0.2"
end

group :pry do
  gem 'byebug'
  gem "pry", '~> 0.10.3'
  #gem "pry-debugger", '~> 0.2.3'
  gem "pry-rails", '~> 0.3.4'
end

gem 'searchkick', '~> 1.3.1'
gem 'typhoeus', '~> 1.0.2'
gem 'faraday_middleware-aws-signers-v4', '~> 0.1.5'
