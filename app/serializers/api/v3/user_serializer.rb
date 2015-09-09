module Api
  module V3
    class UserSerializer < ActiveModel::Serializer
      attributes :id, :name, :email, :created_at, :location_id, :location, :listserv_id, :listserv_name, :test_group, :user_image_url

      def location_id
        object.location.id
      end

      def location
        object.location.name
      end

      def listserv_id
        object.location.try(:listserv).try(:id)
      end

      def listserv_name
        object.location.try(:listserv).try(:name)
      end

      def user_image_url
        object.try(:avatar).try(:url)
      end
    end
  end
end
