module Api
  module V3
    class DetailedMarketPostSerializer < ActiveModel::Serializer

      attributes :id, :title, :price, :content, :content_id, :published_at, :locate_address,
        :can_edit, :has_contact_info, :images, :extended_reach_enabled, :author_name

      root 'market_post'

      def price
        object.try(:channel).try(:cost)
      end

      def title
        object.sanitized_title
      end

      def content
        object.sanitized_content
      end

      # if object has a market post attached, we want to return the market post's ID here
      def id
        object.try(:channel).try(:id) || object.id
      end


      def content_id
        object.id
      end

      def published_at 
        object.pubdate 
      end

      def locate_address
        object.try(:channel).try(:locate_address)
      end
      
      def can_edit
        serialization_options[:can_edit]
      end

      # if user-generated, contact_phone and/or contact_email should be present, else if not user generated
      #  authoremail should be available.  has_contact_info should almost always be true
      def has_contact_info
        object.try(:channel).try(:contact_phone).present? or \
          object.try(:channel).try(:contact_email).present? or \
            object.try(:authoremail).present?
      end

      def images
        object.images.map do |img|
          {
            id: img.id,
            image_url: img.image.url,
            primary: img.primary ? 1 : 0
          }
        end
      end

      def extended_reach_enabled
        object.location_ids.include? Location::REGION_LOCATION_ID
      end

      def author_name
        if object.created_by.present?
          object.created_by.name
        else
          object.authors
        end
      end

    end
  end
end
