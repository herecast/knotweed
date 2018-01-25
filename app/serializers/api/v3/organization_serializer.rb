module Api
  module V3
    class OrganizationSerializer < ActiveModel::Serializer

      attributes :id, :name, :can_publish_news, :subscribe_url,
        :business_profile_id, :description, :org_type, :can_edit, :profile_title,
        :can_publish_events, :can_publish_market, :can_publish_talk, :can_publish_ads,
        :profile_ad_override, :profile_image_url, :background_image_url, :claimed,
        :twitter_handle, :custom_links, :biz_feed_active, :phone, :website,
        :hours, :email, :address, :city, :state, :zip, :certified_storyteller, :services,
        :contact_card_active, :description_card_active, :hours_card_active,
        :special_link_url, :special_link_text, :certified_social, :desktop_image_url

      def profile_image_url
       object.profile_image_url || object.logo_url
     end

      def background_image_url; object.background_image.url if object.background_image.present?; end

      def business_profile_id
        bp_content = object.contents.where(channel_type: 'BusinessProfile').first
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
        object.get_profile_ad_override_id
      end

      def claimed
        business_location.try(:business_profile).try(:claimed?) || false
      end

      def phone
        business_location.try(:phone)
      end

      def website
        business_location.try(:venue_url)
      end

      def hours
        business_location.try(:hours)
      end

      def email
        business_location.try(:email)
      end

      def address
        business_location.try(:address)
      end

      def city
        business_location.try(:city)
      end

      def state
        business_location.try(:state)
      end

      def zip
        business_location.try(:zip)
      end

      private

        def business_location
          object.business_locations.try(:first)
        end

    end
  end
end