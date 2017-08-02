module Api
  module V3
    class ContentSerializer < ActiveModel::Serializer

      attributes :id, :title, :image_url, :author_id, :author_name, :content_type,
        :organization_id, :organization_name,
        :published_at, :starts_at, :ends_at, :content, :view_count, :commenter_count,
        :comment_count, :click_count, :parent_content_id, :content_id, :parent_content_type,
        :event_instance_id, :parent_event_instance_id, :registration_deadline,
        :created_at, :updated_at, :redirect_url, :event_id, :cost, :avatar_url,
        :organization_profile_image_url, :biz_feed_public, :sunset_date, :campaign_start,
        :campaign_end, :base_location_names, :content_locations

      def content_id
        object.id
      end

      def event_instance_id
        if object.channel_type == 'Event'
          object.channel.next_or_first_instance.try(:id)
        end
      end

      def image_url
        if object.root_content_category_id == campaign_content_category_id
          object.promotions.first.promotable.banner_image.try(:url)
        elsif object.images.present?
          object.images[0].image.url
        end
      end

      def author_id
        object.created_by.try(:id)
      end

      def content_type
        object.root_content_category.try(:name)
      end

      def venue_name
        if object.channel_type == 'Event'
          object.channel.try(:venue).try(:name)
        end
      end

      def venue_city
        if object.channel_type == 'Event'
          object.channel.try(:venue).try(:city)
        end
      end

      def venue_state
        if object.channel_type == 'Event'
          object.channel.try(:venue).try(:state)
        end
      end

      def venue_address
        if object.channel_type == 'Event'
          object.channel.try(:venue).try(:address)
        end
      end

      def starts_at
        if object.channel_type == 'Event'
          object.channel.next_or_first_instance.try(:start_date)
        end
      end

      def ends_at
        if object.channel_type == 'Event'
          object.channel.next_or_first_instance.try(:end_date)
        end
      end

      def published_at
        object.pubdate
      end

      def content
        if object.sanitized_content.match(/No content found/)
          ""
        else
          object.sanitized_content
        end
      end

      def title
        object.sanitized_title
      end

      def view_count
        if object.root_content_category_id == campaign_content_category_id
          object.promotions.includes(:promotable).first.promotable.try(:impression_count)
        elsif object.parent.present?
          object.parent_view_count
        else
          object.view_count
        end
      end

      def commenter_count
        if object.parent.present?
          object.parent_commenter_count
        else
          object.commenter_count
        end
      end

      def comment_count
        if object.parent.present?
          object.parent_comment_count
        else
          object.comment_count
        end
      end

      def click_count
        if object.root_content_category_id == campaign_content_category_id
          object.promotions.first.promotable.try(:click_count)
        end
      end

      def parent_content_id
        object.parent_id
      end

      def parent_event_instance_id
        if object.parent.present? and object.parent.channel_type == 'Event'
          object.parent.channel.event_instances.first.id
        end
      end

      def parent_content_type
        if object.parent.present?
          object.parent.root_content_category.name
        end
      end

      def registration_deadline
        if object.channel_type == 'Event'
          object.channel.try(:registration_deadline)
        end
      end

      def base_location_names
        object.base_locations.map(&:name)
      end

      def content_locations
        object.content_locations.map do |cl|
          {
            id: cl.id,
            location_type: cl.location_type,
            location_id: cl.location.slug
          }
        end
      end

      def filter(keys)

        if isEvent
          return keys | %w(
            event_instance_id venue_name venue_address
            venue_city venue_state parent_event_instance_id
            registration_deadline
          )
        end

        keys
      end

      def redirect_url
        if object.root_content_category_id == campaign_content_category_id
          object.promotions.first.promotable.try(:redirect_url)
        end
      end

      def event_id
        if object.channel_type == 'Event'
          object.channel.id
        end
      end

      def cost
        if object.channel_type == 'MarketPost'
          object.channel.cost
        end
      end

      def avatar_url
        object.created_by.try(:avatar_url)
      end

      def organization_profile_image_url
        object.organization.try(:profile_image_url)
      end

      def campaign_start
        if object.root_content_category_id == campaign_content_category_id
          object.promotions.first.promotable.try(:campaign_start)
        end
      end

      def campaign_end
        if object.root_content_category_id == campaign_content_category_id
          object.promotions.first.promotable.try(:campaign_end)
        end
      end

      private

      def isEvent
        (object.channel_type == "Event") || (
          object.parent.present? and
          object.parent.channel_type == 'Event'
        )
      end

      def campaign_content_category_id
        ContentCategory.find_or_create_by(name: 'campaign').id
      end
    end
  end
end
