require 'spec_helper'

describe Api::V2::ContentsController do

  describe 'GET related_promotion' do
    before do
      @event = FactoryGirl.create :event
      @repo = FactoryGirl.create :repository
      @related_content = FactoryGirl.create(:content)
      Promotion.any_instance.stub(:update_active_promotions).and_return(true)
      @promo = FactoryGirl.create :promotion, content: @related_content
      @banner = FactoryGirl.create :promotion_banner, promotion: @promo
      Content.any_instance.stub(:get_related_promotion).and_return(@related_content.id)
    end

    it 'has 200 status code' do
      get :related_promotion, format: :json, 
        event_id: @event.id, repository_id: @repo.id
      response.code.should eq('200')
    end

  end

end
