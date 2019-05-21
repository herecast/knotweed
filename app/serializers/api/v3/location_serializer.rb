# frozen_string_literal: true

module Api
  module V3
    class LocationSerializer < ActiveModel::Serializer
      attributes :id,
                 :city,
                 :state,
                 :latitude,
                 :longitude,
                 :image_url

      def image_url
        object.image_url
      end
    end
  end
end
