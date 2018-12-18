# frozen_string_literal: true

module SearchIndexing
  class LocationSerializer < ActiveModel::Serializer
    attributes :id, :slug, :name, :city, :state, :zip
  end
end
