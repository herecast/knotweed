module Api
  module V3
    class NewsSerializer < ActiveModel::Serializer

      attributes :id, :title, :image_url, :author_name, :author_id, :organization_name,
        :organization_id, :published_at, :content, :created_at, :updated_at, :base_location_names

      def image_url
        if object.images.present?
          object.images[0].image.url
        end
      end

      def author_id
        object.created_by.try(:id)
      end

      def published_at
        object.pubdate
      end

      def title
        object.sanitized_title
      end

      def content
        object.sanitized_content
      end

      def base_location_names
        object.base_locations.map(&:name) | object.organization.base_locations.map(&:name)
      end
    end
  end
end
