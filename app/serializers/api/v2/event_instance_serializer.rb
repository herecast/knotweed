module Api
  module V2
    class EventInstanceSerializer < ActiveModel::Serializer

      attributes :id, :subtitle, :starts_at, :ends_at, :image_url, :content,
        :venue_name, :venue_address, :venue_locate_name, :venue_url,
        :venue_city, :venue_state, :venue_id, :venue_latitude, :venue_longitude,
        :event_url, :venue_locate_name, :venue_zip

      SHARED_EVENT_ATTRIBUTES = [:cost, :contact_phone, :contact_email, :title, :event_url, :cost_type]

      SHARED_EVENT_ATTRIBUTES.each do |w|
        define_method(w) do
          object.event.send(w)
        end
      end

      def filter(keys)
        keys += SHARED_EVENT_ATTRIBUTES
        keys
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

    end
  end
end
