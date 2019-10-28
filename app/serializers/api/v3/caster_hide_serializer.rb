# frozen_string_literal: true

module Api
  module V3
    class CasterHideSerializer < ActiveModel::Serializer
      attributes :id,
                 :flag_type,
                 :caster_id,
                 :caster_name,
                 :caster_handle,
                 :caster_avatar_image_url


      def caster_name
        object.caster.name
      end

      def caster_handle
        object.caster.handle
      end

      def caster_avatar_image_url
        object.caster.avatar_url
      end
    end
  end
end
