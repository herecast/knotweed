# frozen_string_literal: true

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
        date_range.map do |date|
          report_match = content_reports.find { |cr| cr.report_date.to_date == date }
          if report_match.present?
            report_match.view_count_hash
          else
            {
              report_date: Time.parse(date.to_s),
              view_count: 0
            }
          end
        end
      end

      def daily_promo_click_thru_counts
        date_range.map do |date|
          report_match = content_reports.find { |cr| cr.report_date.to_date == date }
          if report_match.present?
            report_match.banner_click_hash
          else
            {
              report_date: Time.parse(date.to_s),
              banner_click_count: 0
            }
          end
        end
      end

      private

      def date_range
        (Date.parse(context[:start_date])..Date.parse(context[:end_date]))
      end

      def content_reports
        @content_reports ||= object.content_reports.where('report_date >= ?', context[:start_date])
                                   .where('report_date <= ?', Date.parse(context[:end_date]) + 1)
      end
    end
  end
end
