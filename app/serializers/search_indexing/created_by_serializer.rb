# frozen_string_literal: true

module SearchIndexing
  class CreatedBySerializer < ActiveModel::Serializer
    attributes :id, :name, :avatar_url
  end
end
