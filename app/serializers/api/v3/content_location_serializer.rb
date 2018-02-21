module Api
  module V3
    class ContentLocationSerializer < ActiveModel::Serializer
      attributes :id,
        :location_id,
        :location_name,
        :location_type

      def location_id
        object.location.slug
      end

      def location_name
        object.location.name
      end
    end
  end
end
