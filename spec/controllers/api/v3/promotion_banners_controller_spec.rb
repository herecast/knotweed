require 'spec_helper'

describe Api::V3::PromotionBannersController do

  describe 'post track_click' do
    before do
      @banner = FactoryGirl.create :promotion_banner
      @content = FactoryGirl.create :content
      @content.promotion_banners = [@banner]
    end

    subject! { post :track_click, promotion_banner_id: @banner.id,  content_id: @content.id, format: :json }

    it 'should respond with 200' do
      response.status.should eq 200
    end

    it 'should increment content.banner_click_count' do
      assigns(:content).banner_click_count.should eq 1
    end

    it 'should increment banner.click_count' do
      assigns(:banner).click_count.should eq 1
    end

    context 'with invalid content id' do
      subject! { post :track_click, promotion_banner_id: @banner.id, content_id: @content.id + 200, format: :json }
      it 'should return 422' do
        response.status.should eq 422
      end
    end

    context 'with invalid promotion_banner_id' do
      subject! { post :track_click, promotion_banner_id: @banner.id + 201, content_id: @content.id, format: :json }
      it 'should return 422' do
        response.status.should eq 422
      end
    end
  end

end
