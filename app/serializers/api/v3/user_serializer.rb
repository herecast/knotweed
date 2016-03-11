module Api
  module V3
    class UserSerializer < ActiveModel::Serializer
      attributes :id, :name, :email, :created_at, :location_id, :location, 
        :listserv_id, :listserv_name, :test_group, :user_image_url, :events_ical_url,
        :skip_analytics, :managed_organization_ids

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

      def events_ical_url
        if object.public_id.present?
          serialization_options[:events_ical_url]
        end
      end

      # this will likely need to change as role authorization gets more complex
      def managed_organization_ids
        if context.present? and context[:current_ability]
          Organization.accessible_by(context[:current_ability], :manage).pluck(:id)
        else
          []
        end
      end
    end
  end
end
