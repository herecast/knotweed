# == Schema Information
#
# Table name: market_posts
#
#  id                       :integer          not null, primary key
#  cost                     :string(255)
#  contact_phone            :string(255)
#  contact_email            :string(255)
#  contact_url              :string(255)
#  locate_name              :string(255)
#  locate_address           :string(255)
#  latitude                 :float
#  longitude                :float
#  locate_include_name      :boolean
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  status                   :string(255)
#  preferred_contact_method :string(255)
#
module Api
  module V3
    # note, this serializer actually takes content objects, not market post objects
    class MarketPostSerializer < ActiveModel::Serializer

      attributes :id, :title, :published_at, :image_url, :content_id,
        :cost, :created_at, :updated_at, :sold

      def content_id
        object.id
      end

      def title
        object.sanitized_title
      end

      def published_at
        object.pubdate
      end

      def image_url
        # NOTE: this works because the primary_image method returns images.first
        # if no primary image exists (or nil if no image exists at all)
        object.primary_image.try(:image).try(:url)
      end

      def cost
        object.try(:channel).try(:cost)
      end

      def sold
        if object.channel
          object.channel.sold
        else
          false
        end
      end
    end
  end
end
