module Api
  module V3
    class DetailedNewsSerializer < ActiveModel::Serializer

      attributes :id, :content_id, :admin_content_url, :content, :title, :subtitle,
        :author_name, :author_id, :publication_name, :publication_id, :published_at

      has_many :images

      def content_id
        object.id
      end

      def admin_content_url
        serialization_options[:admin_content_url]
      end

      def content
        object.sanitized_content
      end

      def author_name
        object.authors
      end

      def author_id
      end

      def publication_name
        object.publication.name
      end

      def published_at
        object.pubdate
      end

    end
  end
end
