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

      def daily_view_counts
        object.content_reports.map do |report|
          {
            report_date: report.report_date,
            view_count: report.view_count
          }
        end
      end

      def daily_promo_click_thru_counts
        object.content_reports.map do |report|
          {
            report_date: report.report_date,
            banner_click_count: report.banner_click_count
          }
        end
      end

    end
  end
end
