module Api
  module V3
    class TalkSerializer < ActiveModel::Serializer

      attributes :id, :title, :user_count, :author_name,
        :author_image_url, :published_at, :view_count, :commenter_count, :comment_count, 
        :parent_content_id, :content_id, :parent_content_type, :parent_event_instance_id

      def content_id
        object.id
      end

      def title
        object.sanitized_title
      end

      def user_count
        # PENDING
        0
      end

      # NOTE: we won't have a "created_by" in content that is imported,
      # use created_by when availble else fall back to authors.
      def author_name
        if object.created_by.present?
          object.created_by.name
        else
          object.authors
        end
      end

      def author_image_url
        object.created_by.try(:avatar).try(:url)
      end

      def published_at
        object.pubdate
      end

      def view_count
        if object.parent.present?
          object.parent.view_count
        else
          object.view_count
        end
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

      def parent_content_id
        if object.parent.present?
          object.parent.id
        end
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
