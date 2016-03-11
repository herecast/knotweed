module Api
  module V3
    class DashboardContentSerializer < ActiveModel::Serializer

      attributes :id, :title, :parent_content_id, :content_type, :comment_count,
        :view_count, :published_at, :event_id, :parent_content_type,
        :parent_event_instance_id, :content_id, :has_metrics_reports?

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

      # this is redundant for everything other than events,
      # but we need it for events because `id` is returning
      # an instance ID
      def content_id
        object.id
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

      def parent_event_instance_id
        if object.parent.present? and object.parent.channel_type == 'Event'
          object.parent.channel.event_instances.first.id
        end
      end

      def content_type
        if object.channel_type.nil?
          'News'
        else
          object.channel_type
        end
      end

      def published_at
        object.pubdate
      end

      def parent_content_type
        if object.parent.present?
          object.parent.root_content_category.name
        end
      end

      def view_count
        if object.parent.present?
          object.parent_view_count
        else
          object.view_count
        end
      end

      def comment_count
        if object.parent.present?
          object.parent_comment_count
        else
          object.comment_count
        end
      end

    end
  end
end
