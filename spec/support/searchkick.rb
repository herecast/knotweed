# frozen_string_literal: true

INDEXED_MODELS = [Content, Organization, BusinessLocation, EventInstance, Location].freeze

def build_indices
  INDEXED_MODELS.each(&:reindex)
end

INDEXED_MODELS.each do |model|
  model.class_eval do
    def reindex_with_refresh(method_name = nil, **options)
      # replacing `mode: :async` with `mode: :inline` here, AND triggering index refresh
      self.reindex_without_refresh(method_name, options.merge({mode: :inline}))
      self.class.search_index.refresh
    end
    alias_method :reindex_without_refresh, :reindex
    alias_method :reindex, :reindex_with_refresh
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    Searchkick.disable_callbacks
  end

  config.around(:each, elasticsearch: true) do |example|
    Searchkick.callbacks(true) do
      example.run
    end
  end

  config.before(:each, elasticsearch: true) do |example|
    build_indices
  end
end
