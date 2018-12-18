# frozen_string_literal: true

class UpdatePromotionBannerDigestMetrics
  def self.call(*args)
    new(*args).call
  end

  def initialize(banner)
    @banner = banner
  end

  def call
    digests = ListservDigest.where("promotion_ids && '{?}'", @banner.promotion.id)

    new_digest_clicks = 0
    new_digest_opens = 0
    new_digests_sent = 0

    digests.each do |digest|
      new_digests_sent += digest.emails_sent
      new_digest_opens += digest.opens_total
      new_digest_clicks += digest.clicks_for_promo(@banner.promotion)
    end

    old_digest_clicks = @banner.digest_clicks || 0
    old_digest_opens = @banner.digest_opens || 0

    clicks_change = 0
    if new_digest_clicks > old_digest_clicks
      clicks_change = new_digest_clicks - old_digest_clicks
    end

    impressions_change = 0
    if new_digest_opens > old_digest_opens
      impressions_change = new_digest_opens - old_digest_opens
    end

    @banner.update(
      digest_clicks: new_digest_clicks,
      digest_emails: new_digests_sent,
      digest_opens: new_digest_opens,
      digest_metrics_updated: Time.current
    )

    @banner.increment!(:impression_count, impressions_change)
    @banner.increment!(:click_count, clicks_change)
  end
end
