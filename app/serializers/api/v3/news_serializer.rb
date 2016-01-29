module Api
  module V3
    class NewsSerializer < ActiveModel::Serializer

      attributes :id, :title, :image_url, :author_name, :author_id, :organization_name,
        :organization_id, :published_at, :content

      def image_url
        if object.images.present?
          object.images[0].image.url
        end
      end

      def author_id
        object.created_by.try(:id)
      end

      def author_name
        object.authors
      end

      def organization_name; object.organization.name; end

      def published_at
        object.pubdate
      end

      def title
        object.sanitized_title
      end

      def content
        object.sanitized_content
      end

    end
  end
end
