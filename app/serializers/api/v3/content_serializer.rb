module Api
  module V3
    class ContentSerializer < ActiveModel::Serializer
      attributes :id,
        :author_id,
        :author_name,
        :avatar_url,
        :base_location_ids,
        :base_locations_array,
        :biz_feed_public,
        :campaign_end,
        :campaign_start,
        :click_count,
        :comment_count,
        :commenter_count,
        :contact_email,
        :contact_phone,
        :content,
        :content_origin,
        :content_type,
        :cost,
        :cost_type,
        :created_at,
        :ends_at,
        :event_url,
        :event_instance_id,
        :event_instances,
        :images,
        :image_url,
        :organization_biz_feed_active,
        :organization_id,
        :organization_name,
        :organization_profile_image_url,
        :parent_content_id,
        :parent_content_type,
        :parent_event_instance_id,
        :promote_radius,
        :published_at,
        :redirect_url,
        :registration_deadline,
        :schedules,
        :sold,
        :split_content,
        :starts_at,
        :subtitle,
        :sunset_date,
        :title,
        :location_id,
        :updated_at,
        :venue_address,
        :venue_city,
        :venue_name,
        :venue_state,
        :venue_url,
        :venue_zip,
        :view_count

      def event_instance_id
        if object.channel_type == 'Event'
          object.channel.try(:next_or_first_instance).try(:id)
        end
      end

      def image_url
        if object.root_content_category.try(:name) == 'campaign' && object.promotions.present?
          object.promotions.first.try(:promotable).try(:banner_image).try(:url)
        elsif object.images.present?
          object.images[0].image.url
        end
      end

      def event_url
        object.channel.try(:event_url)
      end

      def images
        object.images.sort_by{|i| [i.position.to_i, i.created_at]}.map do |img|
          {
            id: img.id,
            caption: img.caption,
            content_id: img.imageable_id,
            file_extension: img.file_extension,
            height: img.height,
            image_url: img.image.url,
            position: img.position,
            primary: img.primary?,
            width: img.width
          }
        end
      end

      def author_id
        object.created_by.try(:id)
      end

      def content_type
        object.content_type
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

      def venue_zip
        if object.channel_type == 'Event'
          object.channel.try(:venue).try(:zip)
        end
      end

      def venue_url
        if object.channel_type == 'Event'
          object.channel.try(:venue).try(:venue_url)
        end
      end

      def venue_address
        if object.channel_type == 'Event'
          object.channel.try(:venue).try(:address)
        end
      end

      def starts_at
        if object.channel_type == 'Event'
          object.channel.try(:next_or_first_instance).try(:start_date)
        end
      end

      def event_url
        if object.channel_type == 'Event'
          object.channel.try(:event_url)
        end
      end
      def ends_at
        if object.channel_type == 'Event'
          object.channel.try(:next_or_first_instance).try(:end_date)
        end
      end

      def published_at
        object.pubdate
      end

      def content
        object.sanitized_content
      end

      def title
        object.sanitized_title
      end

      def view_count
        if object.root_content_category.try(:name) == 'campaign'
          object.promotions.includes(:promotable).first.try(:promotable).try(:impression_count)
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
        if object.root_content_category.try(:name) == 'campaign'
          object.promotions.first.try(:promotable).try(:click_count)
        end
      end

      def parent_content_id
        object.parent_id
      end

      def parent_event_instance_id
        if object.parent.present? and object.parent.channel_type == 'Event'
          object.parent.channel.try(:event_instances).try(:first).try(:id)
        end
      end

      def parent_content_type
        if object.parent.present? and object.parent.root_content_category.present?
          object.parent.root_content_category.name
        end
      end

      def registration_deadline
        if object.channel_type == 'Event'
          object.channel.try(:registration_deadline)
        end
      end

      def redirect_url
        if object.root_content_category.try(:name) == 'campaign'
          object.promotions.first.try(:promotable).try(:redirect_url)
        end
      end

      def cost
        object.channel.try(:cost)
      end

      def sold
        if object.channel_type == 'MarketPost'
          object.channel.try(:sold)
        end
      end

      def avatar_url
        object.created_by.try(:avatar_url)
      end

      def organization_profile_image_url
        object.organization.try(:profile_image_url) || object.organization.try(:logo_url)
      end

      def organization_name
        object.organization.try :name
      end

      def campaign_start
        object.ad_campaign_start
      end

      def campaign_end
        object.ad_campaign_end
      end

      def content_origin
        object.organization&.id == Organization::LISTSERV_ORG_ID ? 'listserv' : 'ugc'
      end

      def event_instances
        if object.channel_type == "Event"
          (object.channel.try(:event_instances) || []).map do |inst|
            AbbreviatedEventInstanceSerializer.new(inst).serializable_hash
          end
        end
      end

      def split_content
        if object.content_type == :news
          SplitContentForAdPlacement.call(
            ImageUrlService.optimize_image_urls(
              html_text: content,
              default_width:  600,
              default_height: 1800,
              default_crop:   false
            )
          ).tap do |h|
            if h[:tail].nil?
              h[:tail] = ""
            end
          end
        end
      end

      def cost_type
        if object.channel_type == 'Event'
          object.channel.try(:cost_type)
        end
      end

      def contact_phone
        object.channel.try(:contact_phone)
      end

      def contact_email
        if [:market, :event].include? object.content_type
          if object.channel.present?
            object.channel.try(:contact_email)
          else
            object.authoremail
          end
        end
      end

      def organization_biz_feed_active
        !!object.organization.try(:biz_feed_active)
      end

      def base_location_ids
        base_locations_array.map{ |l| l[:slug] }.compact
      end

      def base_locations_array
        base_locations.map do |bl|
          {
            slug: bl.slug,
            name: bl.pretty_name
          }
        end
      end

      def location_id
        object.content_locations.to_a.select(&:base?).first.try(:location).try(:slug)
      end

      def schedules
        if isEvent
          object.channel.try(:schedules).try(:map, &:to_ux_format)
        end
      end

      private

        def isEvent
          (object.channel_type == "Event") || (
            object.parent.present? and
            object.parent.channel_type == 'Event'
          )
        end

        def base_locations
          if object.base_locations.present?
            object.base_locations
          elsif object.organization.present?
            object.organization.consumer_active_base_locations
          else
            []
          end
        end
    end
  end
end
