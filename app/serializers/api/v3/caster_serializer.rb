# frozen_string_literal: true

module Api
  module V3
    class CasterSerializer < ActiveModel::Serializer
      attributes :id,
                 :avatar_image_url,
                 :background_image_url,
                 :name,
                 :handle,
                 :user_id,
                 :description,
                 :email,
                 :email_is_public,
                 :website,
                 :location,
                 :total_comment_count,
                 :total_like_count,
                 :total_post_count,
                 :total_view_count,
                 :active_follower_count

      def avatar_image_url
        object.avatar.url
      end

      def user_id
        object.id
      end

      def email
        object.email_is_public ? object.email : nil
      end

      def location
        {
          id: object.location.id,
          city: object.location.city,
          state: object.location.state,
          latitude: object.location.latitude,
          longitude: object.location.longitude,
          image_url: object.location.image_url
        }
      end

      def total_comment_count
        Comment.where(created_by_id: object.id).count
      end

      def total_post_count
        object.post_count
      end

      def total_view_count
        object.total_view_count
      end
    end
  end
end
