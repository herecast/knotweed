module Api
  module V3
    class NewsSerializer < ActiveModel::Serializer

      attributes :id, :title, :image_url, :author_name, :author_id, :publication_name,
        :publication_id, :published_at, :content

      def image_url
        if object.images.present?
          object.images[0].image.url
        end
      end

      # we don't have this field yet. Returning authoremail for now
      def author_id
        object.authoremail
      end

      def author_name
        object.authors
      end

      def publication_name
        object.publication.name
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

    end
  end
end
