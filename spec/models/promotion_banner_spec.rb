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
#  load_count             :integer          default(0)
#  integer                :integer          default(0)
#  promotion_type         :string
#  cost_per_impression    :float
#  cost_per_day           :float
#  coupon_email_body      :text
#  coupon_image           :string
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

    context "when both cost_per_impression and cost_per_day are present" do
      before do
        @promotion_banner = FactoryGirl.build :promotion_banner,
          cost_per_day: 6.45,
          cost_per_impression: 0.12
      end

      it "is not valid" do
        expect(@promotion_banner).not_to be_valid
      end
    end

    context "when promotion is type: coupon" do
      it "requires a coupon image" do
        promotion_banner = FactoryGirl.build :promotion_banner,
          promotion_type: PromotionBanner::COUPON,
          coupon_image: nil
        expect(promotion_banner).not_to be_valid
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
        daily_max_impressions: 5, daily_impression_count: one_more_than_actual_allowance(5),
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
        daily_max_impressions: 5, daily_impression_count: one_more_than_actual_allowance(5) }

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
        daily_impression_count: one_more_than_actual_allowance(5), impression_count: 5 }

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
      let(:banner) { FactoryGirl.create :promotion_banner, campaign_start: 2.weeks.from_now,
        campaign_end: 3.weeks.from_now }

      subject { PromotionBanner.active(banner.campaign_start + 1.minute) }

      it 'should return banners active at that time' do
        expect(subject).to include(banner)
      end
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

  describe "#generate_coupon_click_redirect" do
    it "auto generates coupon click url" do
      promotion_banner = FactoryGirl.build(:promotion_banner,
        promotion_type: PromotionBanner::COUPON,
        coupon_image:   File.open(File.join(Rails.root, '/spec/fixtures/photo.jpg'))
      )
      promotion_banner.save
      expect(promotion_banner.reload.redirect_url).to eq "/promotions/#{promotion_banner.id}"
    end
  end

  def one_more_than_actual_allowance(daily_max)
    (daily_max + (daily_max * PromotionBanner::OVER_DELIVERY_PERCENTAGE)).ceil
  end

end
