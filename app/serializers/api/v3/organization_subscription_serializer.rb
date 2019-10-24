# frozen_string_literal: true

module Api
  module V3
    class OrganizationSubscriptionSerializer < ActiveModel::Serializer
      attributes :id,
                 :organization_id,
                 :organization_name,
                 :organization_profile_image_url

      def organization_id
        object.caster&.organization&.id
      end

      def organization_name
        object.caster&.organization&.name
      end

      def organization_profile_image_url
        object.caster&.organization&.profile_image_url
      end
    end
  end
end
