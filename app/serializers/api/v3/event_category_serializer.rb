module Api
  module V3
    class EventCategorySerializer < ActiveModel::Serializer
      attributes :id, :name, :slug
    end
  end
end