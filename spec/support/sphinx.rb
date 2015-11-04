module SphinxHelpers
  def index
    ThinkingSphinx::Test.index
    sleep 0.25 until index_finished?
  end

  def index_finished?
    state = Dir[Rails.root.join(ThinkingSphinx::Test.config.indices_location, '*.{new,tmp}*')].empty?
    Rails.logger.info "Waiting for ThinkingSphinx to complete indexing, remove #{ThinkingSphinx::Test.config.indices_location}/*.tmp files if this message prints indefinitely" unless state
    state
  end
end

RSpec.configure do |config|
  config.include SphinxHelpers

  config.before(:suite) do
    # Ensure sphinx directories exist for the test environment
    ThinkingSphinx::Test.init
    # Configure and start Sphinx, and automatically
    # stop Sphinx at the end of the test suite.
    ThinkingSphinx::Test.start_with_autostop
  end

  config.before(:each) do
    # Index data when running specs that require sphinx
    index if example.metadata[:sphinx]
  end

end
