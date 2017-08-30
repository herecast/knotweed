module SearchIndexing
  class LocationSerializer < ActiveModel::Serializer
    attributes :id, :slug, :name, :city, :state, :zip
  end
end
