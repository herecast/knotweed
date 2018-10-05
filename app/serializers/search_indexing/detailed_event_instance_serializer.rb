module SearchIndexing
  class DetailedEventInstanceSerializer < ::Api::V3::EventInstanceSerializer
    attributes :published,
      :event_category,
      :all_loc_ids,
      :about_location_ids,
      :removed

    def published
      object.event.content.published
    end

    def event_category
      object.event.event_category
    end

    def removed
      object.event.content.removed
    end

    def all_loc_ids
      object.event.content.all_loc_slugs
    end

    def about_location_ids
      object.event.content.about_locations.map(&:slug)
    end
  end
end
