module Api
  module V3
    class EventInstanceSerializer < ActiveModel::Serializer
      attributes :id, :title, :subtitle, :starts_at, :ends_at, :image_url,
        :venue_name, :venue_address, :venue_city, :venue_state, :venue_url,
        :venue_longitude, :venue_latitude, :venue_locate_name,
        :venue_zip, :presenter_name, :registration_deadline, :cost_type,
        :created_at, :updated_at, :image_width, :image_height, :image_file_extension,
        :author_id, :author_name, :avatar_url, :organization_id, :organization_name, :organization_profile_image_url, :organization_biz_feed_active, :published_at, 
        :content,
        :content_id, :comment_count, :cost, :contact_email, :contact_phone, :updated_at, :event_id, :ical_url, :can_edit

      has_many :comments, serializer: Api::V3::CommentSerializer
      has_many :event_instances, serializer: Api::V3::RelatedEventInstanceSerializer
      has_many :content_locations, serializer: Api::V3::ContentLocationSerializer
      def ical_url
        context[:ical_url] if context.present?
      end

      def can_edit
        if context.present? && context[:current_ability].present?
          context[:current_ability].can?(:manage, object)
        else
          false
        end
      end

      def event_instances
        object.other_instances
      end

      def content_locations
        object.event.content.content_locations
      end

      def comments
        object.event.content.comments
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

      def author_id
        object.event.content.created_by.try :id
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
