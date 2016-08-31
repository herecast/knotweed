INDEXED_MODELS = [Content, BusinessLocation, Organization, BusinessProfile, EventInstance]

def build_indices
  INDEXED_MODELS.each do |model|
    model.reindex
  end
end

INDEXED_MODELS.each do |model|
  model.class_eval do
    def reindex
      self.class.searchkick_index.reindex_record(self)
      self.class.searchkick_index.refresh
    end

    # this feels sort of hacky -- but jobs are just run inline in testing, so while 
    # everything is async in the app, it's not here, so we just need to add the refresh call
    # after this method happens (since it's actually synchronous).
    def reindex_async
      self.class.searchkick_index.reindex_record(self)
      self.class.searchkick_index.refresh
    end
  end
end

RSpec.configure do |config|
  # only actually make calls to Elasticsearch for specs that need it
  # to make other specs run faster
  config.before(:each) do |example|
    if example.metadata[:elasticsearch]
      build_indices
    else
      INDEXED_MODELS.each do |model|
        allow_any_instance_of(model).to receive(:reindex).and_return true
        allow_any_instance_of(model).to receive(:reindex_async).and_return true
      end
    end
  end
end
