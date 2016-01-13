module Api
  module V3
    class DetailedTalkSerializer < ActiveModel::Serializer

      attributes :id, :title, :content, :content_id, :image_url, :user_count,
        :author_name, :author_image_url, :published_at, :view_count, :commenter_count, :comment_count, 
        :parent_content_id, :parent_content_type, :author_email

      def title
        object.sanitized_title
      end

      def content
        object.sanitized_content
      end

      def content_id
        object.id
      end

      def id
        if object.channel.present?
          object.channel_id
        else
          object.id
        end
      end

      def image_url
        if object.images.present?
          object.images[0].image.url
        end
      end

      def user_count
        # PENDING
      end

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

      def author_email
        if object.created_by.present?
          object.created_by.email
        else
          object.authoremail
        end
      end

      def published_at
        object.pubdate
      end

      def view_count
        object.view_count
      end

      def commenter_count
        object.commenter_count
      end

      def comment_count
        object.comment_count
      end

      def parent_content_id
        object.parent_id
      end

      def parent_content_type
        if object.parent.present?
          object.parent.root_content_category.name
        end
      end

    end

  end
end
