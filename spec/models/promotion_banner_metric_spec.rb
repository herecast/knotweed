require 'rails_helper'

RSpec.describe PromotionBannerMetric, type: :model do

  context "when no promotion_banner_id" do
    it "PromotionBannerMetric is not valid" do
      promotion_banner_metric = FactoryGirl.build :promotion_banner_metric, promotion_banner_id: nil
      expect(promotion_banner_metric).to_not be_valid 
    end
  end

  context "when promotion_banner_id is present" do
    it "PromotionBannerMetric is valid" do
      promotion_banner = FactoryGirl.create :promotion_banner
      promotion_banner_metric = FactoryGirl.build :promotion_banner_metric, promotion_banner_id: promotion_banner.id
      expect(promotion_banner_metric).to be_valid
    end
  end
end
