module Api
  module V3
    class DetailedNewsSerializer < ActiveModel::Serializer

      attributes :id, :content_id, :admin_content_url, :content, :title, :subtitle,
        :author_name, :author_id, :organization_name, :organization_id, :published_at, :comment_count,
        :is_sponsored_content

      has_many :images

      def content_id
        object.id
      end

      def admin_content_url
        serialization_options[:admin_content_url]
      end

      def title
        object.sanitized_title
      end

      def content
        object.sanitized_content
      end

      def author_name
        object.authors
      end

      def author_id
      end

      def organization_name
        object.organization.name
      end

      def published_at
        object.pubdate
      end

      def comment_count
        object.comment_count
      end

      def is_sponsored_content
        object.is_sponsored_content?
      end

    end
  end
end
