if ENV['RAILS_ENV'] == 'test' && ENV['COVERAGE'] == 'true'
  require 'simplecov'
  SimpleCov.start
end
