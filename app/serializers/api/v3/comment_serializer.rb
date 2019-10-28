# frozen_string_literal: true

module Api
  module V3
    class CommentSerializer < ActiveModel::Serializer
      attributes :id,
                 :content,
                 :content_id,
                 :parent_id,
                 :published_at,
                 :caster_id,
                 :caster_name,
                 :caster_handle,
                 :caster_avatar_image_url

      def id
        object.channel&.id
      end

      def content
        object.sanitized_content
      end

      def content_id
        object.id
      end

      def published_at
        object.pubdate
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
    end
  end
end
