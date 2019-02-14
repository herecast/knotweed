# frozen_string_literal: true

module Api
  module V3
    class PaymentsSerializer < ActiveModel::Serializer
      attributes :period_start,
                 :period_end,
                 :paid_impressions,
                 :total_payment,
                 :payment_date,
                 :views,
                 :report_url

      def views
        ContentMetric.views_by_user_and_period(
          period_start: object.period_start,
          period_end: object.period_end,
          user: context[:user_id]
        )
      end

      def report_url
        api_v3_payment_reports_path(
          period_start: object.period_start,
          period_end: object.period_end,
          user_id: context[:user_id]
        )
      end
    end
  end
end
