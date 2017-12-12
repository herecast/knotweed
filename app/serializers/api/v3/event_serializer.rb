module Api
  module V3
    class EventSerializer < ActiveModel::Serializer
      attributes :cost, :contact_phone, :contact_email, :title, :cost_type, :content,
        :image_url, :social_enabled, :id,
        :venue_name, :venue_address, :venue_locate_name, :venue_url,
        :venue_city, :venue_state, :venue_id, :venue_latitude, :venue_longitude,
        :venue_locate_name, :venue_zip,
        :event_url, :schedules, :created_at, :updated_at,
        :registration_deadline, :registration_url,
        :registration_phone, :registration_email,
        :content_id,
        :first_instance_id, :category, :owner_name, :can_edit,
        :promote_radius,
        :ugc_base_location_id

      has_many :content_locations, serializer: Api::V3::ContentLocationSerializer

      def ugc_base_location_id
        object.content.content_locations.select(&:base?).first.try(:location).try(:slug)
      end

      def promote_radius
        object.content.promote_radius
      end

      # this is funky but without it, active model serializer tries to use the URL helper
      # event_url instead of the attribute.
      def event_url
        object.event_url
      end

      def title
        object.content.title
      end

      def content
        object.content.sanitized_content
      end

      def content_id
        object.content.id
      end

      def image_url
        if object.content.images.present?
          object.content.images[0].image.url
        end
      end

      def first_instance_id
        object.event_instance_ids.first
      end

      def venue_name
        object.venue.try(:name)
      end

      def venue_address
        object.venue.try(:address)
      end

      def venue_city
        object.venue.try(:city)
      end

      def venue_state
        object.venue.try(:state)
      end

      def venue_zip
        object.venue.try(:zip)
      end

      def venue_id
        object.venue.try(:id)
      end

      def venue_latitude
        object.venue.try(:latitude)
      end

      def venue_longitude
        object.venue.try(:longitude)
      end

      def venue_locate_name
        object.venue.try(:geocoding_address)
      end

      def venue_url
        object.venue.try(:venue_url)
      end

      def schedules
        object.schedules.map{ |s| s.to_ux_format }
      end

      def category
        object.event_category
      end

      def can_edit
        if context.present? && context[:current_ability].present?
          context[:current_ability].can?(:manage, object.content)
        else
          false
        end
      end

      def content_locations
        object.content.content_locations
      end
    end
  end
end
