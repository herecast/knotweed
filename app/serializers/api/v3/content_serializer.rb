# frozen_string_literal: true

module Api
  module V3
    class ContentSerializer < ActiveModel::Serializer
      attributes :id,
                 :biz_feed_public,
                 :campaign_end,
                 :campaign_start,
                 :caster,
                 :caster_handle,
                 :caster_name,
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
                 :embedded_ad,
                 :ends_at,
                 :event_instance_id,
                 :event_instances,
                 :images,
                 :image_url,
                 :like_count,
                 :location,
                 :location_id,
                 :parent_content_id,
                 :parent_content_type,
                 :parent_event_instance_id,
                 :promote_radius,
                 :published_at,
                 :redirect_url,
                 :registration_deadline,
                 :schedules,
                 :short_link,
                 :sold,
                 :split_content,
                 :starts_at,
                 :subtitle,
                 :sunset_date,
                 :title,
                 :updated_at,
                 :url,
                 :venue_id,
                 :venue_address,
                 :venue_city,
                 :venue_name,
                 :venue_state,
                 :venue_url,
                 :venue_zip,
                 :view_count

      def caster
        if caster_object
          {
            id: caster_object.id,
            name: caster_object.name,
            handle: caster_object.handle,
            description: caster_object.description,
            avatar_image_url: caster_object.avatar_url,
            active_followers_count: caster_object.active_follower_count,
            location: {
              id: caster_object.location.id,
              city: caster_object.location.city,
              state: caster_object.location.state,
              latitude: caster_object.location.latitude,
              longitude: caster_object.location.longitude,
              image_url: caster_object.location.image_url
            }
          }
        else
          {}
        end
      end

      def caster_handle
        if caster_object
          caster_object.handle
        end
      end

      def caster_name
        if caster_object
          caster_object.name || caster_object.organization&.name
        end
      end

      def event_instance_id
        if object.channel_type == 'Event'
          object.channel.try(:next_or_first_instance).try(:id)
        end
      end

      def image_url
        if object.content_category == 'campaign' && object.promotions.present?
          object.promotions.first.try(:promotable).try(:banner_image).try(:url)
        elsif object.images.present?
          object.images[0].image.url
        end
      end

      def images
        object.images.sort_by { |i| [i.position.to_i, i.created_at] }.map do |img|
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
        object.created_by_id
      end

      def content_type
        object.content_type
      end

      def venue_id
        object.channel.try(:venue).try(:id) if object.channel_type == 'Event'
      end

      def venue_name
        object.channel.try(:venue).try(:name) if object.channel_type == 'Event'
      end

      def venue_city
        object.channel.try(:venue).try(:city) if object.channel_type == 'Event'
      end

      def venue_state
        object.channel.try(:venue).try(:state) if object.channel_type == 'Event'
      end

      def venue_zip
        object.channel.try(:venue).try(:zip) if object.channel_type == 'Event'
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

      def ends_at
        if object.channel_type == 'Event'
          object.channel.try(:next_or_first_instance).try(:end_date)
        end
      end

      def published_at
        object.pubdate
      end

      def content
        ImageUrlService.optimize_image_urls(
          html_text: object.sanitized_content,
          default_width:  600,
          default_height: 1800,
          default_crop:   false
        )
      end

      def title
        object.sanitized_title
      end

      def view_count
        object.built_view_count
      end

      def commenter_count
        if object.parent.present?
          object.parent.commenter_count
        else
          object.commenter_count
        end
      end

      def comment_count
        if object.parent.present?
          object.parent.comment_count
        else
          object.comment_count
        end
      end

      def click_count
        if object.content_category == 'campaign'
          object.promotions.first.try(:promotable).try(:click_count)
        end
      end

      def parent_content_id
        object.parent_id
      end

      def parent_event_instance_id
        if object.parent.present? && (object.parent.channel_type == 'Event')
          object.parent.channel.try(:event_instances).try(:first).try(:id)
        end
      end

      def parent_content_type
        if object.parent.present? && object.parent.content_category.present?
          object.parent.content_type
        end
      end

      def registration_deadline
        if object.channel_type == 'Event'
          object.channel.try(:registration_deadline)
        end
      end

      def redirect_url
        if object.content_category == 'campaign'
          object.promotions.first.try(:promotable).try(:redirect_url)
        end
      end

      def cost
        object.channel.try(:cost)
      end

      def sold
        object.channel.try(:sold) if object.channel_type == 'MarketPost'
      end

      def avatar_url
        object.created_by.try(:avatar_url)
      end

      def campaign_start
        object.ad_campaign_start
      end

      def campaign_end
        object.ad_campaign_end
      end

      def content_origin
        'ugc'
      end

      def event_instances
        if object.channel_type == 'Event'
          (object.channel.try(:event_instances) || []).map do |inst|
            AbbreviatedEventInstanceSerializer.new(inst).serializable_hash
          end
        end
      end

      def split_content
        SplitContentForAdPlacement.call(
          ImageUrlService.optimize_image_urls(
            html_text: content,
            default_width: 600,
            default_height: 1800,
            default_crop: false
          )
        ).tap do |h|
          h[:tail] = '' if h[:tail].nil?
        end
      end

      def cost_type
        object.channel.try(:cost_type) if object.channel_type == 'Event'
      end

      def contact_phone
        object.channel.try(:contact_phone)
      end

      def contact_email
        if %w[market event].include? object.content_type
          if object.channel.present?
            object.channel.try(:contact_email)
          else
            object.authoremail
          end
        end
      end

      def schedules
        object.channel.try(:schedules).try(:map, &:to_ux_format) if isEvent
      end

      def embedded_ad
        object.embedded_ad?
      end

      def location
        # object.location returns false when there is no location
        # after upgrading searchkick, so safe navigation operator
        # now returns an error -- hence need to change approach here
        if object.location
          {
            id: object.location.id,
            city: object.location.city,
            state: object.location.state,
            latitude: object.location.latitude,
            longitude: object.location.longitude,
            image_url: object.location.image_url
          }
        else
          {}
        end
      end

      private

      def caster_object
        @caster_object ||= Caster.find_by(id: object.created_by_id)
      end

      def isEvent
        (object.channel_type == 'Event') || (
          object.parent.present? &&
          (object.parent.channel_type == 'Event')
        )
      end
    end
  end
end
