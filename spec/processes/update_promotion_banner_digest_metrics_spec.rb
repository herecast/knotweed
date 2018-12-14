# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdatePromotionBannerDigestMetrics do
  context 'Given a promotion banner with digests having metrics' do
    let!(:promotion_banner) do
      FactoryGirl.create :promotion_banner,
                         impression_count: 1,
                         click_count: 1,
                         digest_clicks: 1,
                         digest_emails: 1,
                         digest_opens: 1,
                         digest_metrics_updated: 1.week.ago
    end

    let!(:digest1) do
      FactoryGirl.create :listserv_digest,
                         promotion_ids: [promotion_banner.promotion.id],
                         opens_total: 7,
                         emails_sent: 1,
                         link_clicks: {
                           promotion_banner.redirect_url => '3'
                         }
    end

    let!(:digest2) do
      FactoryGirl.create :listserv_digest,
                         promotion_ids: [promotion_banner.promotion.id],
                         opens_total: 3,
                         emails_sent: 2,
                         link_clicks: {
                           promotion_banner.redirect_url => '5'
                         }
    end

    subject do
      described_class.call(promotion_banner)
    end

    it 'Updates the digest metrics as expected' do
      subject
      promotion_banner.reload
      expect(promotion_banner.digest_emails).to eql 3
      expect(promotion_banner.digest_opens).to eql 10
      expect(promotion_banner.digest_clicks).to eql 8
    end

    it 'increments the impression and click counts from digest data' do
      subject
      promotion_banner.reload

      expect(promotion_banner.impression_count).to eql 10
      expect(promotion_banner.click_count).to eql 8
    end
  end
end
