require 'rails_helper'

RSpec.describe SchedulePromotionMetricsUpdateJob, type: :job do
  let!(:recent_promotion_banner) { FactoryGirl.create :promotion_banner, campaign_start: 5.days.ago }
  let!(:older_promotion_banner) { FactoryGirl.create :promotion_banner, campaign_start: 3.weeks.ago }

  let!(:old_digest) {
    FactoryGirl.create :listserv_digest,
                       mc_campaign_id: 7897,
                       promotion_ids: [older_promotion_banner.promotion.id]
  }
  let!(:recent_digest) {
    FactoryGirl.create :listserv_digest,
                       mc_campaign_id: 123,
                       promotion_ids: [recent_promotion_banner.promotion.id]
  }
  let!(:recent_digest2) {
    FactoryGirl.create :listserv_digest,
                       mc_campaign_id: 6489,
                       promotion_ids: [recent_promotion_banner.promotion.id]
  }

  it 'enqueues UpdateDigestMetrics for promotion_banners active in past 2 weeks' do
    ActiveJob::Base.queue_adapter = :test
    described_class.new.perform

    expect(BackgroundJob).to have_been_enqueued.with(UpdateDigestMetrics.name, 'call', recent_digest)
    expect(BackgroundJob).to have_been_enqueued.with(UpdateDigestMetrics.name, 'call', recent_digest2)
  end

  it 'does not enqueue UpdateDigestMetrics for older promo banners' do
    ActiveJob::Base.queue_adapter = :test
    described_class.new.perform

    expect(BackgroundJob).to_not have_been_enqueued.with('UpdateDigestMetrics', 'call', old_digest)
  end

  it 'schedules UpdatePromotionBannerDigestMetrics in 1 hour for each recent promo banner' do
    ActiveJob::Base.queue_adapter = :test
    Timecop.freeze do
      described_class.new.perform

      expect(BackgroundJob).to have_been_enqueued.with(UpdatePromotionBannerDigestMetrics.name, 'call', recent_promotion_banner).at(1.hour.from_now)
      expect(BackgroundJob).to_not have_been_enqueued.with(UpdatePromotionBannerDigestMetrics.name, 'call', older_promotion_banner)
    end
  end
end
