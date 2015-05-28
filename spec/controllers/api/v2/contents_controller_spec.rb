require 'spec_helper'

describe Api::V2::ContentsController do
  before do
    @repo = FactoryGirl.create :repository
  end

  describe 'GET related_promotion' do
    before do
      @event = FactoryGirl.create :event
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

  describe 'GET similar_content' do
    before do
      @event = FactoryGirl.create :event
      @sim_content = FactoryGirl.create :content
      Content.any_instance.stub(:similar_content).with(@repo).and_return([@sim_content])
    end

    subject { get :similar_content, format: :json,
        event_id: @event.id, repository: @repo.dsp_endpoint }

    it 'has 200 status code' do
      subject
      response.code.should eq('200')
    end

    it 'responds with relation of similar content' do
      subject
      assigns(:contents).should eq([@sim_content])
    end
  end

end