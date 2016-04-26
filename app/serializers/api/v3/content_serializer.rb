module Api
  module V3
    class ContentSerializer < ActiveModel::Serializer

      attributes :id, :title, :image_url, :author_id, :author_name, :content_type,
        :organization_id, :organization_name, :venue_name, :venue_address,
        :published_at, :starts_at, :ends_at, :content, :view_count, :commenter_count, 
        :comment_count, :parent_content_id, :content_id, :parent_content_type, 
        :event_instance_id, :parent_event_instance_id

      def content_id
        object.id
      end

      def event_instance_id
        if object.channel_type == 'Event'
          object.channel.next_or_first_instance.try(:id)
        end
      end

      def image_url
        if object.images.present?
          object.images[0].image.url
        end
      end

      def author_id
        object.created_by.try(:id)
      end

      def content_type
        object.root_content_category.name
      end

      def venue_name
        if object.channel_type == 'Event'
          object.channel.try(:venue).try(:name)
        end
      end

      def venue_address
        if object.channel_type == 'Event'
          object.channel.try(:venue).try(:address)
        end
      end

      def starts_at
        if object.channel_type == 'Event'
          object.channel.next_or_first_instance.try(:start_date)
        end
      end

      def ends_at
        if object.channel_type == 'Event'
          object.channel.next_or_first_instance.try(:end_date)
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
        if object.parent.present?
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

      def parent_content_id
        object.parent_id
      end

      def parent_event_instance_id
        if object.parent.present? and object.parent.channel_type == 'Event'
          object.parent.channel.event_instances.first.id
        end
      end

      def parent_content_type
        if object.parent.present?
          object.parent.root_content_category.name
        end
      end

    end
  end
end
