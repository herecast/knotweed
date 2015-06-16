require 'spec_helper'

describe Api::V2::PromotionBannersController do

  describe 'GET track_click' do
    before do
      @banner = FactoryGirl.create :promotion_banner
    end

    it 'should iterate click_count' do
      count = @banner.click_count
      get :track_click, id: @banner.id
      @banner.reload.click_count.should eq(count+1)
    end

  end

end
