# frozen_string_literal: true

module Api
  module V3
    class CasterFollowSerializer < ActiveModel::Serializer
      attributes :id,
                 :caster_id,
                 :caster_name,
                 :caster_handle,
                 :caster_avatar_image_url


      def caster_name
        object.caster&.name || object.organization&.name
      end

      def caster_handle
        object.caster&.handle
      end

      def caster_avatar_image_url
        object.caster&.avatar_url || object.organization&.profile_image_url
      end
    end
  end
end
