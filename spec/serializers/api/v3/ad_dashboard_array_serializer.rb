require 'spec_helper'

describe Api::V3::AdDashboardArraySerializer do

  describe 'serializer_for' do
    before do
      @promotion = FactoryGirl.create :promotion
      @content = FactoryGirl.create :content
      @serializer = Api::V3::AdDashboardArraySerializer.new([@promotion, @content])
    end

    it 'should respond with an instance of DashboardPromotionBannerSerializer for Promotion content' do
      expect{@serializer.serializer_for(@promotion).is_a?(Api::V3::DashboardPromotionBannerSerializer)}.to be_true
    end

    it 'should respond with an instance of DashboardContentSerializer for other content' do
      expect{@serializer.serializer_for(@content).is_a?(Api::V3::DashboardContentSerializer)}.to be_true
    end
  end
end
