module SearchIndexing
  class DetailedEventInstanceSerializer < ::Api::V3::EventInstanceSerializer
    attributes :published, :event_category, :all_loc_ids, :base_location_ids, :about_location_ids, :my_town_only, :removed

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
      object.event.content.all_loc_ids
    end

    def base_location_ids
      ids = object.event.content.base_locations.map(&:id)
      if object.event.organization.present?
        ids |= object.event.content.organization.base_locations.map(&:id)
      end
      ids
    end

    def about_location_ids
      object.event.content.about_locations.map(&:id)
    end

    def my_town_only
      object.event.content.my_town_only
    end

    def filter(keys)
      keys - [:can_edit]
    end
  end
end
