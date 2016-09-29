module Api
  module V3
    class OrganizationSerializer < ActiveModel::Serializer

      attributes :id, :name, :can_publish_news, :subscribe_url, :logo_url,
        :business_profile_id, :description, :org_type, :can_edit, :profile_title,
        :can_publish_events, :can_publish_market, :can_publish_talk, :can_publish_ads,
        :profile_ad_override, :profile_image_url, :background_image_url

      def logo_url; object.logo.url if object.logo.present?; end

      def profile_image_url; object.profile_image.url if object.profile_image.present?; end

      def background_image_url; object.background_image.url if object.background_image.present?; end

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

      def profile_title
        object.profile_title || object.name
      end

      def profile_ad_override
        if object.profile_ad_override.present?
          object.profile_ad_override.to_i
        else
          nil
        end
      end

    end
  end
end
