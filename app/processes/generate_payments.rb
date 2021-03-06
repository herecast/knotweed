# frozen_string_literal: true

class GeneratePayments
  def self.call(*args)
    new(*args).call
  end

  def initialize(opts = {})
    @opts = opts
    # using chronic here incorporates our default Rails timezone (Eastern)
    # plus it's just a bit more versatile since we're not validating the input
    # in any way.
    @period_start = Chronic.parse(opts[:period_start])
    @period_end = Chronic.parse(opts[:period_end])
    @period_ad_rev = opts[:period_ad_rev]
    @period_total_impressions = PromotionBannerMetric.for_payment_period(@period_start, @period_end).count
    if @period_total_impressions > 0
      @pay_per_impression = (@period_ad_rev.to_f / @period_total_impressions).to_d.truncate(4)
    else
      0
    end
    @payments = []
  end

  def call
    PaymentRecipient.all.each do |pr|
      promotion_metrics = []
      promotion_metrics += promotion_metrics_for_user(pr)
      # adds payment hashes to @payments instance variable
      convert_promotion_metrics_to_payments(promotion_metrics, pr.user)
    end

    save_payments!
  end

  private

  def promotion_metrics_for_user(pr)
    promotion_metrics = PromotionBannerMetric.for_payment_period(@period_start, @period_end)
                                             .joins(content: %i[created_by])
                                             .where('contents.created_by_id = ?', pr.user_id)
                                             .select('content_id, COUNT(DISTINCT promotion_banner_metrics.id) as impressions')
                                             .group(:content_id).order(:content_id)
  end

  def convert_promotion_metrics_to_payments(promotion_metrics, user)
    promotion_metrics.each do |cr|
      paid_impressions = cr.impressions
      payment = {
        period_start: @period_start,
        period_end: @period_end,
        paid_impressions: paid_impressions,
        total_payment: (paid_impressions * @pay_per_impression).to_d.truncate(4),
        payment_date: @period_end.next_month.beginning_of_month + 9.days,
        pay_per_impression: @pay_per_impression,
        period_ad_rev: @period_ad_rev,
        content_id: cr.content_id,
        paid_to: user
      }
      @payments << payment
    end
  end

  def save_payments!
    Payment.transaction do
      @payments.each do |p|
        Payment.create!(p)
      end
    end
  end
end
