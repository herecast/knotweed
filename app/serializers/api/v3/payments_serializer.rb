# frozen_string_literal: true

module Api
  module V3
    class PaymentsSerializer < ActiveModel::Serializer
      attributes :period_start,
                 :period_end,
                 :paid_impressions,
                 :pay_per_impression,
                 :total_payment,
                 :payment_date,
                 :report_url,
                 :revenue_share

      def report_url
        if context[:organization_id].present?
          api_v3_payment_reports_path(
            period_start: object.period_start,
            period_end: object.period_end,
            organization_id: context[:organization_id]
          )
        elsif context[:user_id].present?
          api_v3_payment_reports_path(
            period_start: object.period_start,
            period_end: object.period_end,
            user_id: context[:user_id]
          )
        end
      end
    end
  end
end
