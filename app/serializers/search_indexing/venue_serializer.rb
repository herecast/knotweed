# frozen_string_literal: true

module SearchIndexing
  class VenueSerializer < ActiveModel::Serializer
    attributes :id, :name, :address, :city, :state, :zip, :venue_url
  end
end
