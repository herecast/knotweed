# This job schedules both the digest metric update from mailchimp,
# and the caching of the promotion banner metrics on their respective
# records.
#
# It would be nice to use some sort of workflow system that could wait
# until the digests all got updated before kicking off the banner
# updates. Since the promotion banner data is calculated from the digest.
#
# Sidekiq Pro might offer something that could do this through batches.
#
# For now this just schedules the promotion banner updates to happen
# 1 hour after the start of the digest metric updates.  It should be
# sufficient for now.
#

class SchedulePromotionMetricsUpdateJob < ApplicationJob
  def perform(campaign_start_date = 2.weeks.ago)
    promotion_banners = PromotionBanner.where(campaign_start: campaign_start_date..Time.current)

    digests = ListservDigest.where("promotion_ids && '{?}'", promotion_banners.map{|b| b.promotion.id}).where('mc_campaign_id IS NOT NULL')

    digests.each do |digest|
      BackgroundJob.perform_later('UpdateDigestMetrics', 'call', digest)
    end

    promotion_banners.each do |promo_banner|
      BackgroundJob.set(wait: 1.hour).perform_later('UpdatePromotionBannerDigestMetrics', 'call', promo_banner)
    end
  end
end
