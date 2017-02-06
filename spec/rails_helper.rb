require 'spec_helper'

# This file is used by new generated specs, and is supposed to hold
# Rails specific rspec configuration settings.  For now it's a placeholder.

RSpec.configure do |config|
  config.before(:all, inline_jobs: true) do
    @old_queue_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :inline
  end

  config.after(:all, inline_jobs: true) do
    ActiveJob::Base.queue_adapter = @old_queue_adapter
  end

  config.before(:each) do
    # do not carry state between tests
    User.current = nil
  end
end
