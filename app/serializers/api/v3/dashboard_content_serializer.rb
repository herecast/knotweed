module Api
  module V3
    class DashboardContentSerializer < ActiveModel::Serializer

      attributes :id, :title, :parent_content_id, :content_type, :comment_count,
        :view_count, :published_at

      def parent_content_id
        object.try(:parent).try(:id)
      end

      def content_type
        object.channel_type
      end

      def published_at
        object.pubdate
      end

    end
  end
end
