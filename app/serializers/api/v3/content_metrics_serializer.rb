module Api
  module V3
    class ContentMetricsSerializer < ActiveModel::Serializer

      attributes :id, :title, :image_url, :view_count, :comment_count,
        :comments, :promo_click_thru_count, :daily_view_counts, :daily_promo_click_thru_counts

      def image_url
        # NOTE: this works because the primary_image method returns images.first
        # if no primary image exists (or nil if no image exists at all)
        object.primary_image.try(:image).try(:url)
      end

      def comments
        object.comments.map do |comment|
          CommentSerializer.new(comment).serializable_hash
        end
      end

      def promo_click_thru_count
        object.banner_click_count
      end

      # PENDING REPORTS CODE
      def daily_view_counts; []; end
      def daily_promo_click_thru_counts; []; end

    end
  end
end
