# frozen_string_literal: true

module Api
  module V3
    class CurrentUserSerializer < CasterSerializer
      attributes :email,
                 :created_at,
                 :listserv_id,
                 :listserv_name,
                 :skip_analytics,
                 :location_confirmed,
                 :has_had_bookmarks,
                 :is_blogger,
                 :caster_follows,
                 :caster_hides,
                 :feed_card_size,
                 :user_hide_count,
                 :bookmarks,
                 :phone,
                 :publisher_agreement_confirmed

      def email
        object.email
      end

      def listserv_id
        object.location.try(:listserv).try(:id)
      end

      def listserv_name
        object.location.try(:listserv).try(:name)
      end

      def is_blogger
        object.has_role?(:blogger)
      end

      def caster_follows
        object.caster_follows.active.map do |caster_follow|
          CasterFollowSerializer.new(caster_follow, root: false)
        end
      end

      def caster_hides
        object.caster_hides.active.map do |caster_hide|
          CasterHideSerializer.new(caster_hide, root: false)
        end
      end

      def user_hide_count
        object.caster_hiders.count
      end

      def bookmarks
        object.user_bookmarks.map do |bookmark|
          {
            id: bookmark.id,
            content_id: bookmark.content_id
          }
        end
      end

    end
  end
end
