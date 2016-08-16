module Api
  module V3
    class DetailedNewsSerializer < ActiveModel::Serializer

      attributes :id, :content_id, :admin_content_url, :content, :title, :subtitle,
        :author_name, :author_id, :organization_name, :organization_id, :published_at, :comment_count,
        :is_sponsored_content, :updated_at, :can_edit

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

      def author_id
        object.created_by.try(:id)
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

      def can_edit
        if context.present? && context[:current_ability].present?
          context[:current_ability].can?(:manage, object)
        else
          false
        end
      end

    end
  end
end
