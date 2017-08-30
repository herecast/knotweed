module SearchIndexing
  class ContentLocationSerializer < ActiveModel::Serializer
    attributes :id, :location_id, :location_type

    has_one :location, serialalizer: SearchIndexing::LocationSerializer

  end
end
