module Api
  module V3
    class DashboardContentSerializer < ActiveModel::Serializer

      attributes :id, :title, :parent_content_id, :content_type, :comment_count,
        :view_count, :published_at, :event_id, :parent_type

      def id
        # if object is an event, Ember app needs an event instance ID
        # as the ID. This will be revisited in the future, but for now, 
        # is how Peter requested dashboard responses work.
        if object.channel_type == 'Event'
          object.channel.event_instances.first.id
        else
          object.id
        end
      end

      # only set for event type objects
      def event_id
        if object.channel_type == 'Event'
          object.channel_id
        end
      end

      def parent_content_id
        object.try(:parent).try(:id)
      end

      def content_type
        object.channel_type
      end

      def published_at
        object.pubdate
      end

      def parent_type
        if object.parent.present?
          object.parent.root_content_category.name
        end
      end

    end
  end
end
