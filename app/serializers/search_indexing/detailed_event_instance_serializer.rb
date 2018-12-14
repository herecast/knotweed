module SearchIndexing
  class DetailedEventInstanceSerializer < ::Api::V3::EventInstanceSerializer
    attributes :event_category,
               :removed

    def event_category
      object.event.event_category
    end

    def removed
      object.event.content.removed
    end
  end
end
