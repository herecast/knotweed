# frozen_string_literal: true

module Api
  module V3
    class UserSerializer < ActiveModel::Serializer
      attributes :id,
                 :name,
                 :email,
                 :created_at,
                 :location,
                 :listserv_id,
                 :listserv_name,
                 :user_image_url,
                 :skip_analytics,
                 :location_confirmed,
                 :has_had_likes,
                 :is_blogger,
                 :organization_subscriptions,
                 :caster_hides,
                 :feed_card_size,
                 :publisher_agreement_confirmed

      def listserv_id
        object.location.try(:listserv).try(:id)
      end

      def listserv_name
        object.location.try(:listserv).try(:name)
      end

      def user_image_url
        object.try(:avatar).try(:url)
      end

      def is_blogger
        object.has_role?(:blogger)
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

      def organization_subscriptions
        object.caster_follows.active.map do |caster_follow|
          CasterFollowSerializer.new(caster_follow, root: false)
        end
      end

      def caster_hides
        object.caster_hides.active.map do |caster_hide|
          CasterHideSerializer.new(caster_hide, root: false)
        end
      end
    end
  end
end
