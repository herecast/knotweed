module Api
  module V3
    class TalkSerializer < ActiveModel::Serializer

      attributes :id, :title, :user_count, :author_name,
        :author_image_url, :published_at, :view_count, :commenter_count, :comment_count,
        :parent_content_id, :content_id, :parent_content_type, :parent_event_instance_id,
        :created_at, :updated_at, :initial_comment_author, :initial_comment_author_image_url,
        :image_url

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

      def author_image_url
        object.created_by.try(:avatar).try(:url)
      end

      def published_at
        object.latest_activity
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
        object.parent_id || object.id # if parent is not present, we want the object's own ID
      end

      def parent_event_instance_id
        if object.parent.present? and object.parent.channel_type == 'Event'
          object.parent.channel.next_or_first_instance.id
        elsif object.channel_type == 'Event'
          object.channel.next_or_first_instance.id
        end
      end

      def parent_content_type
        if object.parent.present?
          object.parent.root_content_category.name
        else
          object.root_content_category.name
        end
      end

      def initial_comment_author
        object.comments.first.author_name if object.comments.present?
      end

      def initial_comment_author_image_url
        object.comments.first.created_by.try(:avatar).try(:url) if object.comments.present?
      end

      def image_url
        if object.images.present?
          object.images[0].image.url
        end
      end
    end
  end
end
