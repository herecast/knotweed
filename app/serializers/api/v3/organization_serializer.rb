# frozen_string_literal: true

module Api
  module V3
    class OrganizationSerializer < ActiveModel::Serializer
      attributes :id,
                 :name,
                 :can_publish_news,
                 :subscribe_url,
                 :business_profile_id,
                 :description,
                 :org_type,
                 :can_edit,
                 :profile_image_url,
                 :background_image_url,
                 :claimed,
                 :twitter_handle,
                 :custom_links,
                 :biz_feed_active,
                 :phone,
                 :website,
                 :hours,
                 :email,
                 :address,
                 :city,
                 :state,
                 :zip,
                 :certified_storyteller,
                 :services,
                 :contact_card_active,
                 :description_card_active,
                 :hours_card_active,
                 :special_link_url,
                 :special_link_text,
                 :certified_social,
                 :desktop_image_url,
                 :calendar_view_first,
                 :calendar_card_active,
                 :digest_id,
                 :active_subscriber_count,
                 :post_count,
                 :total_view_count,
                 :user_hide_count


      def profile_image_url
        object.profile_image_url || object.logo_url
     end

      def background_image_url
        object.background_image.url if object.background_image.present?
      end

      def business_profile_id
        bp_content = object.contents.where(channel_type: 'BusinessProfile').first
        bp_content.channel_id if bp_content.present?
      end

      def can_edit
        if context.present? && context[:current_ability].present?
          context[:current_ability].can?(:edit, object)
        else
          false
        end
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

      def post_count
        object.contents
              .not_removed
              .where('pubdate IS NOT NULL AND pubdate < ?', Time.current)
              .where("channel_type != 'BusinessProfile' OR channel_type IS NULL")
              .count
      end

      def total_view_count
        object.contents.sum(:view_count).to_i
      end

      def user_hide_count
        object.organization_hides.active.count
      end

      private

      def business_location
        object.business_locations.try(:first)
      end
    end
  end
end
