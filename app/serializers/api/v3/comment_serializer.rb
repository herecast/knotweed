# frozen_string_literal: true

module Api
  module V3
    class CommentSerializer < ActiveModel::Serializer
      attributes :id,
                 :content,
                 :content_id,
                 :parent_id,
                 :pubdate,
                 :published_at,
                 :title,
                 :caster_id,
                 :caster_name,
                 :caster_handle,
                 :caster_avatar_image_url

      def content
        object.sanitized_content
      end

      def parent_id
        object.content_id
      end

      def content_id
        object.id
      end

      def pubdate
        object.pubdate.try(:iso8601)
      end

      def published_at
        object.pubdate.try(:iso8601)
      end

      def caster_id
        object.created_by_id
      end

      def caster_name
        object.created_by&.name || object.created_by&.organization&.name
      end

      def caster_handle
        object.created_by&.handle
      end

      def caster_avatar_image_url
        object.created_by&.avatar_url || object.created_by&.organization&.profile_image_url
      end

      def title
        object.content.try(:title)
      end
    end
  end
end
