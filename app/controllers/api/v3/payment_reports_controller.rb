# frozen_string_literal: true

module Api
  module V3
    class PaymentReportsController < ApiController
      before_action :check_logged_in!

      def index
        @user = User.find(params[:user_id]) if params[:user_id].present?
        authorize! :manage, @user

        @period_start = Date.parse(params[:period_start])
        @period_end = Date.parse(params[:period_end])

        if payments.present?
          sample = payments.first
          @pay_per_impression = sample.pay_per_impression.truncate(4)
          @payment_date = sample.payment_date
          @revenue_share = (payments.sum(:total_payment) * 100 / sample.period_ad_rev).truncate(2) if sample.period_ad_rev.present?
          @paid_impressions = payments.sum(:paid_impressions)
          @total_payment = payments.sum(:total_payment)

          @line_items = line_items
        end
        render 'index', layout: false
      end

      private

      def payments
        pments = Payment.where(paid_to: @user)
        if pments.present?
          pments.where(period_start: @period_start,
                       period_end: @period_end)
        else
          []
        end
      end

      def line_items
        if @user.present?
          payments
            .paid
            .joins(content: [:organization])
            .select('organizations.id, organizations.name as name, SUM(paid_impressions) as total_impressions')
            .group('organizations.id')
        end
      end
    end
  end
end
