module Api
  module V3
    class DetailedEventInstanceSerializer < EventInstanceSerializer

      attributes :event_instances, :content_id, :event_id, :social_enabled, :venue_id, 
        :venue_url, :venue_latitude, :venue_longitude, :event_url, :venue_locate_name, 
        :admin_content_url, :content, :can_edit, :title, :comment_count,
        :registration_deadline, :registration_url, :registration_phone,
        :registration_email

      SHARED_EVENT_ATTRIBUTES = [:cost, :cost_type, :contact_phone, :contact_email, :event_url]

      SHARED_EVENT_ATTRIBUTES.each do |w|
        define_method(w) do
          object.event.send(w)
        end
      end

      def filter(keys)
        keys += SHARED_EVENT_ATTRIBUTES
        keys
      end

      def can_edit
        serialization_options[:can_edit]
      end

      def admin_content_url
        serialization_options[:admin_content_url]
      end

      def event_instances
        object.event.event_instances.map do |inst|
          AbbreviatedEventInstanceSerializer.new(inst).serializable_hash
        end
      end

      def content_id
        object.event.content.id
      end

      def social_enabled
        object.event.social_enabled
      end

      def comment_count
        object.event.comment_count
      end

      def registration_deadline; object.event.registration_deadline; end
      def registration_url; object.event.registration_url; end
      def registration_phone; object.event.registration_phone; end
      def registration_email; object.event.registration_email; end

    end
  end
end
