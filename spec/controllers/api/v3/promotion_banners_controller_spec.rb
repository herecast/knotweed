require 'spec_helper'

describe Api::V3::PromotionBannersController do

  describe 'GET track_click' do
    before do
      banner = FactoryGirl.create :promotion_banner
      @content = FactoryGirl.create :content
      @content.promotion_banners = [banner]
    end

    subject! { get :track_click, id: @content.id, format: :json }

    it 'should increment click_count' do
      assigns(:content).banner_click_count.should eq 1
    end

    context 'with invalid content id' do
      subject! { get :track_click, id: @content.id + 200, format: :json }
      it 'should return 422' do
        response.status.should eq 422
      end
    end
  end

end
