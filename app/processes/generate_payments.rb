class GeneratePayments

  def self.call(*args)
    self.new(*args).call
  end

  def initialize(opts={})
    @opts = opts
    @period_start = DateTime.parse(opts[:period_start])
    @period_end = DateTime.parse(opts[:period_end])
    @period_ad_rev = opts[:period_ad_rev]
    @period_total_impressions = PromotionBannerMetric.for_payment_period(@period_start, @period_end).count
    if @period_total_impressions > 0
      @pay_per_impression = (@period_ad_rev.to_f / @period_total_impressions).to_d.truncate(2)
    else
      0
    end
    @payments = []
  end

  def call
    PaymentRecipient.all.each do |pr|
      promotion_metrics = []
      if pr.organization.present?
        promotion_metrics += promotion_metrics_for_publisher(pr)
      else
        promotion_metrics += promotion_metrics_for_user(pr)
      end
      # adds payment hashes to @payments instance variable
      convert_promotion_metrics_to_payments(promotion_metrics, pr.user)
    end

    save_payments!
  end

  private

  def promotion_metrics_for_user(pr)
    promotion_metrics = PromotionBannerMetric.for_payment_period(@period_start, @period_end).
      joins(content: [:organization, :created_by]).
      where('contents.created_by = ?', pr.user_id).
      where('organizations.pay_for_content = true').
      select('content_id, COUNT(DISTINCT promotion_banner_metrics.id) as impressions').
      group(:content_id).order(:content_id)
  end

  def promotion_metrics_for_publisher(pr)
    promotion_metrics = PromotionBannerMetric.for_payment_period(@period_start, @period_end).
      joins(:content).
      joins('INNER JOIN organizations o ON contents.organization_id = o.id').
      where('o.pay_for_content = true').
      where('o.name = ? OR '\
                 '(SELECT name '\
                 'FROM organizations '\
                 'WHERE id = o.parent_id) = ?',
            pr.organization.name, pr.organization.name).
      select('content_id, COUNT(DISTINCT promotion_banner_metrics.id) as impressions').
      group(:content_id).order(:content_id)
  end

  def convert_promotion_metrics_to_payments(promotion_metrics, user)
    promotion_metrics.each do |cr|
      paid_impressions = cr.impressions
      payment = {
        period_start: @period_start,
        period_end: @period_end,
        paid_impressions: paid_impressions,
        total_payment: (paid_impressions * @pay_per_impression).to_d.truncate(2),
        payment_date: @period_end.next_month.beginning_of_month + 9.days,
        pay_per_impression: @pay_per_impression,
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
