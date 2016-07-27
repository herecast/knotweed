module SphinxHelpers
  def index
    # the migration to postgres seems to have introduced a situation
    # where our db queries (creating objects) are not always complete by the time
    # execution moves on to `index`. If we weren't planning on moving to RT indexing,
    # I'd spend more time trying to debug this, but since it's not a functional issue
    # and we will be moving away from this style of indexing soon anyway, I think this
    # little hack is enough to deal with the random failures we see otherwise.
    sleep 0.25
    ThinkingSphinx::Test.index
    sleep 0.25 until index_finished?
  end

  def index_finished?
    state = Dir[Rails.root.join(ThinkingSphinx::Test.config.indices_location, '*.{new,tmp}*')].empty?
    Rails.logger.info "Waiting for ThinkingSphinx to complete indexing. If this message prints indefinitely, rm #{ThinkingSphinx::Test.config.indices_location}/*.tmp" unless state
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

  # this is not super valuable because it gets registered
  # as the FIRST before action...so if your other before action
  # creates content that you need indexed, you have to do that manually,
  # you can't use this metadata-based shortcut.
  config.before(:each) do
    # Index data when running specs that require sphinx
    index if RSpec.current_example.metadata[:sphinx]
  end

end
