# frozen_string_literal: true

module Api
  module V3
    class EventInstanceSerializer < ActiveModel::Serializer
      attributes :id,
                 :author_id,
                 :author_name,
                 :avatar_url,
                 :biz_feed_public,
                 :comment_count,
                 :commenter_count,
                 :contact_email,
                 :contact_phone,
                 :content,
                 :content_id,
                 :content_origin,
                 :cost,
                 :cost_type,
                 :created_at,
                 :ends_at,
                 :event_id,
                 :ical_url,
                 :images,
                 :image_url,
                 :location_id,
                 :organization_biz_feed_active,
                 :organization_id,
                 :organization_name,
                 :organization_profile_image_url,
                 :presenter_name,
                 :promote_radius,
                 :published_at,
                 :registration_deadline,
                 :starts_at,
                 :subtitle,
                 :title,
                 :updated_at,
                 :url,
                 :venue_address,
                 :venue_city,
                 :venue_latitude,
                 :venue_longitude,
                 :venue_name,
                 :venue_state,
                 :venue_url,
                 :venue_zip

      has_many :comments, serializer: Api::V3::CommentSerializer
      has_many :event_instances, serializer: Api::V3::RelatedEventInstanceSerializer

      def comments
        object.event.content.abridged_comments
      end

      def promote_radius
        object.event.content.promote_radius
      end

      def location_id
        object.event.content.location_id
      end

      def images
        object.event.content.images.sort_by { |i| [i.position.to_i, i.created_at] }.map do |img|
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

      def created_at
        object.event.content.created_at
      end

      def content_origin
        object.event.content.organization&.id == Organization::LISTSERV_ORG_ID ? 'listserv' : 'ugc'
      end

      def biz_feed_public
        object.event.content.biz_feed_public
      end

      def ical_url
        context[:ical_url] if context.present?
      end

      def event_instances
        object.other_instances
      end

      def cost
        object.event.cost
      end

      def cost_type
        object.event.cost_type
      end

      def updated_at
        object.event.content.updated_at
      end

      def contact_email
        object.event.contact_email
      end

      def contact_phone
        object.event.contact_phone
      end

      def event_id
        object.event.id
      end

      def url
        object.event.content.url
      end

      def title
        object.event.title
      end

      def published_at
        object.event.content.pubdate
      end

      def content
        object.event.content.sanitized_content
      end

      def content_id
        object.event.content.id
      end

      def comment_count
        object.event.content.comment_count
      end

      def commenter_count
        object.event.content.commenter_count
      end

      def author_id
        object.event.content.created_by_id
      end

      def author_name
        object.event.content.created_by.try :name
      end

      def avatar_url
        object.event.content.created_by.try :avatar_url
      end

      def organization_biz_feed_active
        object.event.content.organization.try :biz_feed_active
      end

      def organization_id
        object.event.content.organization.try :id
      end

      def organization_name
        object.event.content.organization.try :name
      end

      def organization_profile_image_url
        object.event.content.organization.try(:profile_image_url) ||
          object.event.content.organization.try(:logo_url)
      end

      def subtitle
        object.subtitle_override
      end

      def content
        object.event.content.sanitized_content
      end

      def image_url
        if object.event.content.images.present?
          object.event.content.images[0].image.url
        end
      end

      def image_width
        if object.event.content.images.present?
          object.event.content.images[0].width
        end
      end

      def image_height
        if object.event.content.images.present?
          object.event.content.images[0].height
        end
      end

      def image_file_extension
        if object.event.content.images.present?
          object.event.content.images[0].file_extension
        end
      end

      def starts_at
        object.start_date
      end

      def ends_at
        object.end_date
      end

      def venue_name
        object.event.venue.try(:name)
      end

      def venue_address
        object.event.venue.try(:address)
      end

      def venue_city
        object.event.venue.try(:city)
      end

      def venue_state
        object.event.venue.try(:state)
      end

      def venue_zip
        object.event.venue.try(:zip)
      end

      def venue_id
        object.event.venue.try(:id)
      end

      def venue_latitude
        object.event.venue.try(:latitude)
      end

      def venue_longitude
        object.event.venue.try(:longitude)
      end

      def venue_locate_name
        object.event.venue.try(:geocoding_address)
      end

      def venue_url
        object.event.venue.try(:venue_url)
      end

      def registration_deadline
        object.event.registration_deadline
      end

      def cost_type
        object.event.try(:cost_type)
      end
    end
  end
end
