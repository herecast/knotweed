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
#

require 'spec_helper'

describe PromotionBanner, :type => :model do

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

  describe 'scope :active' do
    before do
      # active promotion banners
      FactoryGirl.create_list :promotion_banner, 3, campaign_start: 1.day.ago, campaign_end: 1.day.from_now
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

    describe "::remove_promotion" do
      it "remove promotion" do
        response = PromotionBanner.remove_promotion(@promotion_banner.promotion.content.repositories[0], @content.id)
        expect(response).to be_a SPARQL::Client
      end
    end

    describe "::remove_paid_promotion" do
      it "removes paid promotion" do
        response = PromotionBanner.remove_paid_promotion(@promotion_banner.promotion.content.repositories[0], @content.id)
        expect(response).to be_a SPARQL::Client
      end
    end
  end

end
