# frozen_string_literal: true

require 'simplecov'

if ENV['COVERAGE'] || ENV['CI']
  SimpleCov.start 'rails' do
    add_filter '/vendor/'

    add_group 'Serializers', 'app/serializers'
  end
end

SimpleCov.minimum_coverage 88

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
require 'rspec/rails'
require 'webmock/rspec'
# require 'pry-debugger' unless ENV['RM_INFO']
require 'factory_girl'
WebMock.disable_net_connect!(allow_localhost: true, allow: [
  ENV['ELASTICSEARCH_URL'],
  %r{bonsaisearch.net}
])

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :controller
  config.include RequestHelpers, type: :request
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  #
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  config.before(:suite) do
    ImageUploader.storage = :file
    DatabaseCleaner.allow_remote_database_url = ENV['CI']
    DatabaseCleaner.strategy = :truncation
    begin
      DatabaseCleaner.start
      FactoryGirl.lint
    ensure
      DatabaseCleaner.clean
    end
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each) do
    ActionMailer::Base.deliveries.clear
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
    FileUtils.rm_rf(Dir["#{Rails.root}/spec/support/uploads"])
    if ActiveJob::Base.queue_adapter.respond_to?(:enqueued_jobs=)
      ActiveJob::Base.queue_adapter.enqueued_jobs = []
      ActiveJob::Base.queue_adapter.performed_jobs = []
    end
  end

  config.around(:each, freeze_time: true) do |example|
    Timecop.freeze(Time.at(100))
    example.run
    Timecop.return
  end
end

Geocoder.configure(lookup: :test)
Geocoder::Lookup::Test.set_default_stub(
  [
    {
      'latitude' => 40.7143528,
      'longitude' => -74.0059731,
      'address' => 'New York, NY, USA',
      'state' => 'New York',
      'state_code' => 'NY',
      'country' => 'United States',
      'country_code' => 'US'
    }
  ]
)
