module Api
  module V3
    class OrganizationSerializer < ActiveModel::Serializer

      attributes :id, :name, :can_publish_news, :subscribe_url, :logo_url,
        :business_profile_id, :description, :org_type

      def logo_url; object.logo.url if object.logo.present?; end

      def business_profile_id
        bp_content= object.contents.where(channel_type: 'BusinessProfile').first
        if bp_content.present?
          bp_content.id
        end
      end

    end
  end
end
