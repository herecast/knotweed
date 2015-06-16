# == Schema Information
#
# Table name: promotion_banners
#
#  id           :integer          not null, primary key
#  banner_image :string(255)
#  redirect_url :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require 'spec_helper'

describe PromotionBanner do

  describe 'scope :for_content' do
    before do
      @banner = FactoryGirl.create :promotion_banner
      @content_id = @banner.promotion.content.id
      FactoryGirl.create_list :promotion_banner, 3 # random others that shouldn't be returned
    end

    it 'should return the promotion banners related to the requested content' do
      PromotionBanner.for_content(@content_id).should eq([@banner])
    end

    it 'should return all promotion banners related to the content' do
      promo2 = FactoryGirl.create :promotion, content_id: @content_id
      banner2 = FactoryGirl.create :promotion_banner, promotion: promo2
      PromotionBanner.for_content(@content_id).count.should eq(2)
    end

  end

  describe 'scope :active' do
    before do
      FactoryGirl.create_list :promotion_banner, 3 # just some generic active banners
    end

    it 'should not include banners that have hit max impressions' do
      over_max = FactoryGirl.create :promotion_banner, impression_count: 50, max_impressions:50
      PromotionBanner.active.include?(over_max).should be_false
    end

    it 'should not include banners whose associated promotion is inactive' do
      inactive = FactoryGirl.create :promotion_banner
      inactive.promotion.update_attribute :active, false
      PromotionBanner.active.include?(inactive).should be_false
    end

    it 'should return active banners' do
      PromotionBanner.active.count.should eq(3)
    end

    it 'should not include banners outside their campaign date range' do
      already_over = FactoryGirl.create :promotion_banner, campaign_start: 3.days.ago,
        campaign_end: 2.days.ago
      not_started = FactoryGirl.create :promotion_banner, campaign_start: 3.days.from_now,
        campaign_end: 5.days.from_now
      PromotionBanner.active.include?(already_over).should be_false
      PromotionBanner.active.include?(not_started).should be_false
    end

  end

end
