# frozen_string_literal: true
# == Schema Information
#
# Table name: promotion_banners
#
#  id                     :bigint(8)        not null, primary key
#  banner_image           :string(255)
#  redirect_url           :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  campaign_start         :date
#  campaign_end           :date
#  max_impressions        :bigint(8)
#  impression_count       :bigint(8)        default(0)
#  click_count            :bigint(8)        default(0)
#  daily_max_impressions  :bigint(8)
#  boost                  :boolean          default(FALSE)
#  daily_impression_count :bigint(8)        default(0)
#  load_count             :integer          default(0)
#  integer                :integer          default(0)
#  promotion_type         :string
#  cost_per_impression    :float
#  cost_per_day           :float
#  coupon_email_body      :text
#  coupon_image           :string
#  sales_agent            :string
#  digest_clicks          :integer          default(0), not null
#  digest_opens           :integer          default(0), not null
#  digest_emails          :integer          default(0), not null
#  digest_metrics_updated :datetime
#  location_id            :bigint(8)
#
# Indexes
#
#  index_promotion_banners_on_location_id  (location_id)
#
# Foreign Keys
#
#  fk_rails_...  (location_id => locations.id)
#

require 'spec_helper'

describe PromotionBanner, type: :model do
  it { is_expected.to have_db_column(:load_count).of_type(:integer).with_options(default: 0) }
  it { is_expected.to have_db_column(:digest_clicks).of_type(:integer).with_options(default: 0) }
  it { is_expected.to have_db_column(:digest_opens).of_type(:integer).with_options(default: 0) }
  it { is_expected.to have_db_column(:digest_emails).of_type(:integer).with_options(default: 0) }
  it { is_expected.to have_db_column(:digest_metrics_updated).of_type(:datetime) }

  describe 'validation' do
    context 'when no banner image present' do
      let(:promotion_banner) { FactoryGirl.build :promotion_banner, banner_image: nil }

      it 'is invalid' do
        expect(promotion_banner.valid?).to be false
      end
    end

    context 'when both cost_per_impression and cost_per_day are present' do
      before do
        @promotion_banner = FactoryGirl.build :promotion_banner,
                                              cost_per_day: 6.45,
                                              cost_per_impression: 0.12
      end

      it 'is not valid' do
        expect(@promotion_banner).not_to be_valid
      end
    end

    context 'when promotion is type: coupon' do
      it 'requires a coupon image' do
        promotion_banner = FactoryGirl.build :promotion_banner,
                                             promotion_type: PromotionBanner::COUPON,
                                             coupon_image: nil
        expect(promotion_banner).not_to be_valid
      end
    end

    context 'when promotion_type is profile_page or promotional_services' do
      before do
        @promotion_banner = FactoryGirl.build :promotion_banner,
                                              campaign_start: Date.today,
                                              campaign_end: Date.tomorrow,
                                              banner_image: nil
      end

      it 'does not need banner_image to be valid' do
        [PromotionBanner::PROFILE_PAGE, PromotionBanner::PROMOTION_SERVICES].each do |type|
          @promotion_banner.promotion_type = type
          expect(@promotion_banner).to be_valid
        end
      end
    end
  end

  describe 'scope :for_content' do
    before do
      @banner = FactoryGirl.create :promotion_banner
      @content_id = @banner.promotion.content.id
      FactoryGirl.create_list :promotion_banner, 3 # random others that shouldn't be returned
    end

    it 'should return the promotion banners related to the requested content' do
      expect(PromotionBanner.for_content(@content_id)).to eq([@banner])
    end

    it 'should return all promotion banners related to the content' do
      promo2 = FactoryGirl.create :promotion, content_id: @content_id
      banner2 = FactoryGirl.create :promotion_banner, promotion: promo2
      expect(PromotionBanner.for_content(@content_id).count).to eq(2)
    end
  end

  describe 'stacking for_content and has_inventory scopes' do
    subject { PromotionBanner.for_content(banner.promotion.content_id).has_inventory }

    context 'a banner with no inventory' do
      let(:banner) do
        FactoryGirl.create :promotion_banner,
                           daily_max_impressions: 5, daily_impression_count: one_more_than_actual_allowance(5),
                           max_impressions: nil
      end

      it 'should not be returned' do
        expect(subject).to_not include(banner)
      end
    end

    context 'a banner with inventory' do
      let(:banner) do
        FactoryGirl.create :promotion_banner,
                           daily_max_impressions: 7, daily_impression_count: 5,
                           max_impressions: nil
      end

      it 'should be returned' do
        expect(subject).to include(banner)
      end
    end
  end

  describe 'scope :has_inventory' do
    subject { PromotionBanner.has_inventory }

    context 'a promotion banner with no impression limits' do
      let(:promotion_banner) do
        FactoryGirl.create :promotion_banner,
                           daily_max_impressions: nil, max_impressions: nil
      end

      it 'should be included' do
        expect(subject).to include(promotion_banner)
      end
    end

    context 'a promotion banner over daily_max_impressions' do
      let(:promotion_banner) do
        FactoryGirl.create :promotion_banner,
                           daily_max_impressions: 5, daily_impression_count: one_more_than_actual_allowance(5)
      end

      it 'should not be included' do
        expect(subject).to_not include(promotion_banner)
      end
    end

    context 'a promotion banner over max_impressions' do
      let(:promotion_banner) do
        FactoryGirl.create :promotion_banner,
                           max_impressions: 5, impression_count: 5
      end

      it 'should not be included' do
        expect(subject).to_not include(promotion_banner)
      end
    end

    context 'a promotion banner over daily_max_impressions but not over max_impressions' do
      let(:promotion_banner) do
        FactoryGirl.create :promotion_banner,
                           daily_max_impressions: 5, max_impressions: 6,
                           daily_impression_count: one_more_than_actual_allowance(5), impression_count: 5
      end

      it 'should not be included' do
        expect(subject).to_not include(promotion_banner)
      end
    end

    context 'a promotion banner over max_impressions but not over daily_max_impressions' do
      let(:promotion_banner) do
        FactoryGirl.create :promotion_banner,
                           daily_max_impressions: 3, max_impressions: 6,
                           daily_impression_count: 2, impression_count: 6
      end

      it 'should not be included' do
        expect(subject).to_not include(promotion_banner)
      end
    end
  end

  describe 'scope :active' do
    let!(:active_banner) { FactoryGirl.create :promotion_banner, :active }
    let!(:inactive_banner) { FactoryGirl.create :promotion_banner, :inactive }

    subject { PromotionBanner.active }
    it 'should return active banners' do
      expect(subject).to match_array [active_banner]
    end

    it 'should not include banners outside their campaign date range' do
      expect(subject).to_not include(inactive_banner)
    end

    describe 'when passed a time argument' do
      let(:banner) do
        FactoryGirl.create :promotion_banner, campaign_start: 2.weeks.from_now,
                                              campaign_end: 3.weeks.from_now
      end

      subject { PromotionBanner.active(banner.campaign_start + 1.minute) }

      it 'should return banners active at that time' do
        expect(subject).to include(banner)
      end
    end
  end

  describe '#active?' do
    before do
      @promotion_banner = FactoryGirl.create :promotion_banner
    end

    context 'when campaign start is after current date' do
      it 'returns false' do
        @promotion_banner.update_attribute(:campaign_start, Date.tomorrow)
        expect(@promotion_banner.reload.active?).to be false
      end
    end

    context 'when campaign end is before current date' do
      it 'returns false' do
        @promotion_banner.update_attribute(:campaign_end, Date.yesterday)
        expect(@promotion_banner.reload.active?).to be false
      end
    end

    context 'when campaign start is >= current date and campaign end is <= current date' do
      it 'returns true' do
        @promotion_banner.update_attributes(
          campaign_start: Date.yesterday,
          campaign_end: Date.tomorrow
        )
        expect(@promotion_banner.reload.active?).to be true
      end
    end
  end

  describe '#has_inventory?' do
    before do
      @promotion_banner = FactoryGirl.create :promotion_banner
    end

    context 'when no daily impressions left and no total impressions left' do
      it 'returns false' do
        @promotion_banner.update_attributes(
          max_impressions: 5,
          impression_count: 6,
          daily_max_impressions: 2,
          daily_impression_count: 3
        )
        expect(@promotion_banner.reload.has_inventory?).to be false
      end
    end

    context 'when no daily impressions left and some total impressions left' do
      it 'returns false' do
        @promotion_banner.update_attributes(
          max_impressions: 10,
          impression_count: 8,
          daily_max_impressions: 3,
          daily_impression_count: 4
        )
        expect(@promotion_banner.reload.has_inventory?).to be false
      end
    end

    context 'when some daily impressions left but no total impressions left' do
      it 'returns false' do
        @promotion_banner.update_attributes(
          max_impressions: 10,
          impression_count: 11,
          daily_max_impressions: 3,
          daily_impression_count: 2
        )
        expect(@promotion_banner.reload.has_inventory?).to be false
      end
    end

    context 'when some daily impressions left and some total impressions left' do
      it 'returns true' do
        @promotion_banner.update_attributes(
          max_impressions: 10,
          impression_count: 8,
          daily_max_impressions: 3,
          daily_impression_count: 2
        )
        expect(@promotion_banner.reload.has_inventory?).to be true
      end
    end
  end

  describe '#active_with_inventory?' do
    before do
      @promotion_banner = FactoryGirl.create :promotion_banner
    end

    context 'when not active and without inventory' do
      it 'returns false' do
        allow_any_instance_of(PromotionBanner).to receive(:active?).and_return false
        allow_any_instance_of(PromotionBanner).to receive(:has_inventory?).and_return false
        expect(@promotion_banner.active_with_inventory?).to be false
      end
    end

    context 'when active and without inventory' do
      it 'returns false' do
        allow_any_instance_of(PromotionBanner).to receive(:active?).and_return true
        allow_any_instance_of(PromotionBanner).to receive(:has_inventory?).and_return false
        expect(@promotion_banner.active_with_inventory?).to be false
      end
    end

    context 'when not active with inventory' do
      it 'returns false' do
        allow_any_instance_of(PromotionBanner).to receive(:active?).and_return false
        allow_any_instance_of(PromotionBanner).to receive(:has_inventory?).and_return true
        expect(@promotion_banner.active_with_inventory?).to be false
      end
    end

    context 'when active with inventory' do
      it 'returns true' do
        allow_any_instance_of(PromotionBanner).to receive(:active?).and_return true
        allow_any_instance_of(PromotionBanner).to receive(:has_inventory?).and_return true
        expect(@promotion_banner.active_with_inventory?).to be true
      end
    end
  end

  describe '#current_daily_report' do
    before do
      @promotion_banner = FactoryGirl.create :promotion_banner
    end

    context 'when no current daily PromotionBannerReport present' do
      it 'returns nil' do
        expect(@promotion_banner.current_daily_report(Date.current)).to be_nil
      end
    end

    context 'when a current daily PromotionBannerReport is present' do
      it 'returns report' do
        promotion_banner_report = FactoryGirl.create(:promotion_banner_report,
                                                     promotion_banner_id: @promotion_banner.id,
                                                     report_date: Date.current)
        expect(@promotion_banner.current_daily_report(Date.current)).to eq promotion_banner_report
      end
    end
  end

  describe '#find_or_create_daily_report' do
    before do
      @promotion_banner = FactoryGirl.create :promotion_banner
    end

    subject { @promotion_banner.find_or_create_daily_report(Date.current) }

    context 'when no current PromotionBannerReport is present' do
      it 'creates current daily PromotionBannerReport' do
        expect { subject }.to change {
          PromotionBannerReport.count
        }.by 1
      end
    end

    context 'when current PromotionBannerReport is present' do
      it 'returns current PromotionBannerReport' do
        promotion_banner_report = FactoryGirl.create(:promotion_banner_report,
                                                     promotion_banner_id: @promotion_banner.id,
                                                     report_date: Date.current)
        expect(subject).to eq promotion_banner_report
      end
    end
  end

  describe '#generate_coupon_click_redirect' do
    it 'auto generates coupon click url' do
      promotion_banner = FactoryGirl.build(:promotion_banner,
                                           promotion_type: PromotionBanner::COUPON,
                                           coupon_image: File.open(File.join(Rails.root, '/spec/fixtures/photo.jpg')))
      promotion_banner.save
      expect(promotion_banner.reload.redirect_url).to eq "/promotions/#{promotion_banner.id}"
    end
  end

  def one_more_than_actual_allowance(daily_max)
    (daily_max + (daily_max * PromotionBanner::OVER_DELIVERY_PERCENTAGE)).ceil
  end
end
