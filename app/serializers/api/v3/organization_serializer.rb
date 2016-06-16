module Api
  module V3
    class OrganizationSerializer < ActiveModel::Serializer

      attributes :id, :name, :can_publish_news, :subscribe_url, :logo_url,
        :business_profile_id, :description, :org_type, :can_edit

      def logo_url; object.logo.url if object.logo.present?; end

      def business_profile_id
        bp_content= object.contents.where(channel_type: 'BusinessProfile').first
        if bp_content.present?
          bp_content.channel_id
        end
      end

      def can_edit
        if context.present? && context[:current_ability].present?
          context[:current_ability].can?(:edit, object)
        else
          false
        end
      end

    end
  end
end
