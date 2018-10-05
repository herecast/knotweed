module Api
  module V3
    class LocationSerializer < ActiveModel::Serializer
      attributes :id,
        :city,
        :state
    end
  end
end
