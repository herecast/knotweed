module SearchIndexing
  class CreatedBySerializer < ActiveModel::Serializer
    attributes :id, :name, :avatar_url
  end
end
