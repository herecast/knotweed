source 'https://rubygems.org'

ruby '1.9.3'
gem 'rails', '3.2.13'
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '~> 2.4.0'
  gem 'compass-rails', '~> 1.1.3'
  gem 'turbo-sprockets-rails3', '~> 0.3.11'
end
gem 'jquery-rails', '~> 3.1.2'
gem "mysql2", '~> 0.3.14'
gem "haml-rails", "~> 0.4"
gem "capybara", "~> 2.2.0", :group => :test
gem "database_cleaner", "~> 1.2.0", :group => :test
gem "email_spec", "~> 1.5.0", :group => :test
gem "rb-inotify", "~> 0.9.3", :group => :development, :require => false
gem "rb-fsevent", "~> 0.9.3", :group => :development, :require => false
gem "rb-fchange", "~> 0.0.6", :group => :development, :require => false
gem "devise", "~> 3.2.2"
gem 'cancancan', '~> 1.10.0'
gem "rolify", "~> 3.2.0"
gem "simple_form", "~> 2.1.1"
gem "quiet_assets", "~> 1.0.2", :group => :development
gem "capistrano", "~> 3.1.0"
gem "capistrano-bundler", "~> 1.1.1"
gem "capistrano-rvm", '~> 0.1.1'
gem "capistrano-rails", "~> 1.1"
gem "rubypress", '~> 1.1.0'
gem 'net-http-persistent', '~> 2.9'
gem 'rinku', "~> 1.7.3"

group :development, :test do
  gem "factory_girl_rails", "~> 4.3.0"
  gem 'faker', '~> 1.6.1'
  gem "rspec-rails", "~> 2.14.0"
  gem 'guard-bundler', require:false
  gem 'guard-rspec', require:false
  gem 'guard-zeus', require: false
end

group :test do
  gem "webmock", '~> 1.17.4'
  gem "vcr", '~> 2.9.2'
  gem "timecop", '~> 0.7.1'
  gem 'simplecov', '~> 0.10.0'
  # this is for circleci to properly read & ormat our test results
  gem 'rspec_junit_formatter', '~> 0.2.3'
end

group :rubymine,:development do
 	gem "thin", '~> 1.6.3'
end
gem "carrierwave", '~> 0.9.0'
gem 'carrierwave-mimetype-fu', '~> 0.0.2'
gem "figaro", '~> 0.7.0'


gem 'jquery-datatables-rails', '~> 3.3.0'

gem 'delayed_job_active_record', '~> 4.0.0'
gem 'daemons', '~> 1.1.9'
gem 'american_date', '~> 1.1.0'

gem 'mail', '~> 2.5.4'
gem 'httparty', '~> 0.12.0'
gem 'chosen-rails', '~> 1.0.2'
gem 'ransack', '~> 1.5.1'
gem 'kaminari', '~> 0.15.0'

gem "nokogiri", '1.6.1' # allowing a patch upgrade on this
# gem breaks part of sanitized content that I can't really figure out
# so I'm leaving it locked into the version we currently use.

gem "fog", '~> 1.19.0'
gem 'unf', '~> 0.1.3'
gem 'datetimepicker-rails', git: 'git://github.com/zpaulovics/datetimepicker-rails', tag: 'v1.0.0'

gem "carmen-rails", '~> 1.0.0'

group :development do
  gem "better_errors", '~> 0.9.0'
  gem "binding_of_caller", '~> 0.7.2'
  gem "annotate", '~> 2.6.5'
  gem "yard", '~> 0.8.7.6'
end

group :pry do
  gem "pry", '~> 0.10.3'
  gem "pry-rails", '~> 0.3.4'
  gem "pry-debugger", '~> 0.2.3'
  gem 'debugger', '~> 1.6.8'
end

gem "turbolinks", '~> 2.2.0'
gem "jquery-turbolinks", '~> 2.1.0'
gem "rubyzip", "~> 1.1.4"

gem "ckeditor_rails", '~> 4.3.1'
gem 'hpricot', '~> 0.8.6'
gem 'active_model_serializers', '~> 0.9.3'
gem 'sparql-client', '~> 1.1.3'

gem 'chronic', '~> 0.10.2'
gem 'geocoder', '~> 1.2.4'
gem 'thinking-sphinx', "~> 3.1.4"
gem 'ts-datetime-delta', '~> 2.0.2', require: 'thinking_sphinx/deltas/datetime_delta'
gem 'jbuilder', '~> 2.1.3'
gem 'mixpanel_client', '~> 4.1.1'
gem 'mixpanel-ruby', '~> 1.4.0' # official ruby mixpanel client. later versions need ruby > 2.0

gem "select2-rails", '~> 3.5.9.1'
gem "legato", '~> 0.4.0'
gem "google-api-client", '~> 0.7.1'
gem 'oauth2', '~> 1.0.0'
gem "rdf", '~> 1.1.6'

gem 'enumerize', '~> 0.11.0'
gem 'newrelic_rpm', '~> 3.13.0.299'

gem 'forecast_io', '~> 2.0.0'

gem 'postmark-rails', '~> 0.12.0'
gem 'whenever', '~> 0.9.2', :require => false

gem 'ice_cube', "~> 0.13.0"
gem 'icalendar', '~> 2.3'

# some gem that depends on net-ssh has a gemspec that tries
# to install a version of net-ssh that requires ruby 2.0.0,
# so we have to specify these two versions here. Same with tins
gem 'net-ssh', '~> 2.7.0'
gem 'tins', '~> 0.13.1'
