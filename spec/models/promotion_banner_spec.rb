# == Schema Information
#
# Table name: promotion_banners
#
#  id                     :integer          not null, primary key
#  banner_image           :string(255)
#  redirect_url           :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  campaign_start         :date
#  campaign_end           :date
#  max_impressions        :integer
#  impression_count       :integer          default(0)
#  click_count            :integer          default(0)
#  daily_max_impressions  :integer
#  boost                  :boolean          default(FALSE)
#  daily_impression_count :integer          default(0)
#  track_daily_metrics    :boolean
#  load_count             :integer          default(0)
#  integer                :integer          default(0)
#

require 'spec_helper'

describe PromotionBanner, :type => :model do

  it {is_expected.to have_db_column(:load_count).of_type(:integer).with_options(default:0)}

  describe 'validation' do
    context "when no banner image present" do
      let(:promotion_banner) { FactoryGirl.build :promotion_banner, banner_image: nil }

      it "is invalid" do
        expect(promotion_banner.valid?).to be false
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
      let(:banner) { FactoryGirl.create :promotion_banner,
        daily_max_impressions: 5, daily_impression_count: 5,
        max_impressions: nil }

      it 'should not be returned' do
        expect(subject).to_not include(banner)
      end
    end

    context 'a banner with inventory' do
      let(:banner) { FactoryGirl.create :promotion_banner,
        daily_max_impressions: 7, daily_impression_count: 5,
        max_impressions: nil }

      it 'should be returned' do
        expect(subject).to include(banner)
      end
    end
  end

  describe 'scope :has_inventory' do
    subject { PromotionBanner.has_inventory } 

    context 'a promotion banner with no impression limits' do
      let(:promotion_banner) { FactoryGirl.create :promotion_banner,
        daily_max_impressions: nil, max_impressions: nil } 

      it 'should be included' do
        expect(subject).to include(promotion_banner)
      end
    end

    context 'a promotion banner over daily_max_impressions' do
      let(:promotion_banner) { FactoryGirl.create :promotion_banner,
        daily_max_impressions: 5, daily_impression_count: 5 }

      it 'should not be included' do
        expect(subject).to_not include(promotion_banner)
      end
    end

    context 'a promotion banner over max_impressions' do
      let(:promotion_banner) { FactoryGirl.create :promotion_banner,
        max_impressions: 5, impression_count: 5 }

      it 'should not be included' do
        expect(subject).to_not include(promotion_banner)
      end
    end

    context 'a promotion banner over daily_max_impressions but not over max_impressions' do
      let(:promotion_banner) { FactoryGirl.create :promotion_banner,
        daily_max_impressions: 5, max_impressions: 6,
        daily_impression_count: 5, impression_count: 5 } 

      it 'should not be included' do
        expect(subject).to_not include(promotion_banner)
      end
    end

    context 'a promotion banner over max_impressions but not over daily_max_impressions' do
      let(:promotion_banner) { FactoryGirl.create :promotion_banner,
        daily_max_impressions: 3, max_impressions: 6,
        daily_impression_count: 2, impression_count: 6 } 

      it 'should not be included' do
        expect(subject).to_not include(promotion_banner)
      end
    end
  end

  describe 'scope :active' do
    before do
      # active promotion banners
      FactoryGirl.create_list :promotion_banner, 3, campaign_start: 2.days.ago, campaign_end: 2.days.from_now
    end

    #it 'should not include banners that have hit max impressions' do
    #  over_max = FactoryGirl.create :promotion_banner, impression_count: 50, max_impressions:50
    #  PromotionBanner.active.include?(over_max).should be_false
    #end

    #it 'should not include banners whose associated promotion is inactive' do
    #  inactive = FactoryGirl.create :promotion_banner
    #  inactive.promotion.update_attribute :active, false
    #  PromotionBanner.active.include?(inactive).should be_false
    #end

    it 'should return active banners' do
      expect(PromotionBanner.active.count).to eq(3)
    end

    it 'should not include banners outside their campaign date range' do
      already_over = FactoryGirl.create :promotion_banner, campaign_start: 3.days.ago,
        campaign_end: 2.days.ago
      not_started = FactoryGirl.create :promotion_banner, campaign_start: 3.days.from_now,
        campaign_end: 5.days.from_now
      expect(PromotionBanner.active.include?(already_over)).to be_falsey
      expect(PromotionBanner.active.include?(not_started)).to be_falsey
    end

  end

  describe "#current_daily_report" do
    before do
      @promotion_banner = FactoryGirl.create :promotion_banner
    end

    context "when no current daily PromotionBannerReport present" do
      it "returns nil" do
        expect(@promotion_banner.current_daily_report(Date.current)).to be_nil
      end
    end

    context "when a current daily PromotionBannerReport is present" do
      it "returns report" do
        promotion_banner_report = FactoryGirl.create(:promotion_banner_report,
          promotion_banner_id: @promotion_banner.id,
          report_date: Date.current
        )
        expect(@promotion_banner.current_daily_report(Date.current)).to eq promotion_banner_report
      end
    end
  end

  describe "#find_or_create_daily_report" do
    before do
      @promotion_banner = FactoryGirl.create :promotion_banner
    end

    subject { @promotion_banner.find_or_create_daily_report(Date.current) }

    context "when no current PromotionBannerReport is present" do
      it "creates current daily PromotionBannerReport" do
        expect{ subject }.to change{
          PromotionBannerReport.count
        }.by 1
      end
    end

    context "when current PromotionBannerReport is present" do
      it "returns current PromotionBannerReport" do
        promotion_banner_report = FactoryGirl.create(:promotion_banner_report,
          promotion_banner_id: @promotion_banner.id,
          report_date: Date.current
        )
        expect(subject).to eq promotion_banner_report
      end
    end
  end

  describe '#update_active_promotions' do
    before do
      @content = FactoryGirl.create :content
      @promotion_banner = FactoryGirl.create :promotion_banner
      @promotion = FactoryGirl.create :promotion, promotable_id: @promotion_banner.id, content_id: @content.id
      stub_request(:any, 'http://test-dsp.subtext.org:8080/graphdb-workbench-se/repositories/subtext/statements')
      @promotion_banner.promotion.content.repositories << FactoryGirl.create(:repository, graphdb_endpoint: 'http://test-dsp.subtext.org:8080/graphdb-workbench-se/repositories/subtext')
    end

    context "when promo has active promotion" do
      it "marks active promotions" do
        response = @promotion_banner.update_active_promotions
        expect(response.length).to eq 1
      end
    end

    context "when promo has no active promotion" do
      it "removes promotion" do
        allow_any_instance_of(Content).to receive(:has_active_promotion?).and_return(false)
        response = @promotion_banner.update_active_promotions
        expect(response.length).to eq 1
      end
    end

    context "when promo has paid promotion" do
      it "marks paid promotion" do
        allow_any_instance_of(Content).to receive(:has_paid_promotion?).and_return(true)
        response = @promotion_banner.update_active_promotions
        expect(response.length).to eq 1
      end
    end

    context "when promo has no paid promotion" do
      it "removes paid promotion" do
        response = @promotion_banner.update_active_promotions
        expect(response.length).to eq 1
      end
    end
  end

end
