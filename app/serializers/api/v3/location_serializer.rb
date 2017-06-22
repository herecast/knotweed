module Api
  module V3
    class LocationSerializer < ActiveModel::Serializer

      attributes :id, :city, :state

      def id
        object.slug
      end
    end
  end
end
