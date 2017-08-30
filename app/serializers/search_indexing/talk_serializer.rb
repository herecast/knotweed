module SearchIndexing
  class TalkSerializer < ContentSerializer

    def base_location_ids
      object.base_locations.map(&:id)
    end
  end
end
