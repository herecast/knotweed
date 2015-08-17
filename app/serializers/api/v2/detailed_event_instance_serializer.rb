module Api
  module V2
    class DetailedEventInstanceSerializer < EventInstanceSerializer

      attributes :event_instances, :content_id, :event_id, :social_enabled,
        :admin_content_url, :can_edit

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

    end
  end
end
