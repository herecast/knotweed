module Api
  module V3
    class UserMetricsSerializer < ActiveModel::Serializer
      attributes :id,
        :promo_click_thru_count,
        :view_count,
        :comment_count,
        :daily_view_counts,
        :daily_promo_click_thru_counts
      
      def promo_click_thru_count
        metrics[:promo_click_thru_count]
      end

      def view_count
        metrics[:view_count]
      end

      def comment_count
        metrics[:comment_count]
      end

      def daily_view_counts
        metrics[:daily_view_counts]
      end

      def daily_promo_click_thru_counts
        metrics[:daily_promo_click_thru_counts]
      end

      private

        def metrics
          @metrics ||= GatherContentMetrics.call(
            user: object,
            start_date: context[:start_date],
            end_date: context[:end_date]
          )
        end
    end
  end
end
