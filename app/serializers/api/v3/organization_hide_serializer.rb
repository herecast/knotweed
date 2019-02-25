module Api
  module V3
    class OrganizationHideSerializer < ActiveModel::Serializer
      attributes :id,
        :flag_type,
        :organization_id,
        :organization_name,
        :organization_profile_image_url

      def organization_id
        object.organization.id
      end

      def organization_name
        object.organization.name
      end

      def organization_profile_image_url
        object.organization.profile_image_url
      end
    end
  end
end