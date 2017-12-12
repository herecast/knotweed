module Api
  module V3
    class DetailedMarketPostSerializer < ActiveModel::Serializer

      attributes :id, :title, :price, :content, :content_id, :published_at,
        :locate_address, :can_edit, :has_contact_info,
        :author_name, :organization_id, :image_url, :contact_phone,
        :contact_email, :preferred_contact_method, :images, :created_at, :updated_at,
        :sold, :promote_radius, :ugc_base_location_id

      root 'market_post'

      has_many :content_locations, serializer: Api::V3::ContentLocationSerializer

      def ugc_base_location_id
        object.content_locations.select(&:base?).first.try(:location).try(:slug)
      end

      def contact_phone
        object.try(:channel).try(:contact_phone)
      end

      def contact_email
        if object.try(:channel).is_a?(MarketPost)
          object.try(:channel).try(:contact_email)
        else
          object.authoremail
        end
      end

      def preferred_contact_method
        object.try(:channel).try(:preferred_contact_method)
      end

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

      def organization_id
        object.organization_id
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
        if object.channel.nil?
          false
        elsif context.present? && context[:current_ability].present?
          context[:current_ability].can?(:manage, object)
        else
          false
        end
      end

      # if user-generated, contact_phone and/or contact_email should be present, else if not user generated
      #  authoremail should be available.  has_contact_info should almost always be true
      def has_contact_info
        object.try(:channel).try(:contact_phone).present? or \
          object.try(:channel).try(:contact_email).present? or \
            object.try(:authoremail).present?
      end

      def images
        object.images.sort_by{|i| [i.position, i.created_at]}.map do |img|
          {
            id: img.id,
            image_url: img.image.url,
            primary: img.primary ? 1 : 0,
            width: img.width,
            height: img.height,
            file_extension: img.file_extension
          }
        end
      end

      def image_url
        # NOTE: this works because the primary_image method returns images.first
        # if no primary image exists (or nil if no image exists at all)
        object.primary_image.try(:image).try(:url)
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
