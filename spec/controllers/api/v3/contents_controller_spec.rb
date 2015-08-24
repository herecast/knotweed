require 'spec_helper'

describe Api::V3::ContentsController do
  before do
    @repo = FactoryGirl.create :repository
  end

  describe 'GET index' do
    before do
      @news_cat = FactoryGirl.create :content_category, name: 'news'
      @tott_cat = FactoryGirl.create :content_category, name: 'talk_of_the_town'
      @market_cat = FactoryGirl.create :content_category, name: 'market'
      @event_cat = FactoryGirl.create :content_category, name: 'event'
      @default_location = FactoryGirl.create :location, city: Location::DEFAULT_LOCATION
      @other_location = FactoryGirl.create :location, city: 'Another City'
      @user = FactoryGirl.create :user, location: @other_location
      FactoryGirl.create_list :content, 3, content_category: @news_cat, 
        locations: [@default_location], published: true
      FactoryGirl.create_list :content, 15, content_category: @market_cat, 
        locations: [@default_location], published: true
      FactoryGirl.create_list :content, 5, content_category: @tott_cat,
        locations: [@default_location], published: true
      FactoryGirl.create_list :content, 5, content_category: @event_cat,
        locations: [@default_location], published: true
      FactoryGirl.create_list :content, 3, content_category: @market_cat, 
        locations: [@other_location]
    end

    subject { get :index, format: :json }

    context 'not signed in' do
      it 'has 200 status code' do
        subject
        response.code.should eq('200')
      end

      it 'should respond with 2 news items' do
        subject
        assigns(:contents).select{|c| c.content_category_id == @news_cat.id }.count.should eq(2)
      end

      it 'should not include any talk items' do
        subject
        assigns(:contents).select{|c| c.content_category_id == @tott_cat.id }.count.should eq(0)
      end

      it 'should only return items in the default location' do
        subject
        assigns(:contents).select{|c| c.locations.include? @other_location }.count.should eq(0)
      end

    end

  end

  describe 'GET related_promotion' do
    before do
      @event = FactoryGirl.create :event
      @content = @event.content
      @related_content = FactoryGirl.create(:content)
      Promotion.any_instance.stub(:update_active_promotions).and_return(true)
      @promo = FactoryGirl.create :promotion, content: @related_content
      @pb = FactoryGirl.create :promotion_banner, promotion: @promo
      Content.any_instance.stub(:get_related_promotion).and_return(@related_content.id)
    end

    subject { get :related_promotion, format: :json, event_id: @event.id, 
              repository_id: @repo.id }

    it 'has 200 status code' do
      subject
      response.code.should eq('200')
    end

    it 'should increment the impression count of the banner' do
      count = @pb.impression_count
      subject
      @pb.reload.impression_count.should eq(count+1)
    end

    describe 'logging content displayed with' do

      it 'should create a ContentPromotionBannerImpression record if none exists' do
        subject
        ContentPromotionBannerImpression.count.should eq(1)
        ContentPromotionBannerImpression.first.content_id.should eq(@content.id)
        ContentPromotionBannerImpression.first.promotion_banner_id.should eq(@pb.id)
      end

      it 'should increment the ContentPromotionBannerImpression display count if a record exists' do
        cpbi = FactoryGirl.create :content_promotion_banner_impression, content_id: @content.id, promotion_banner_id: @pb.id
        subject
        cpbi.reload.display_count.should eq(2)
      end
      
    end

  end

  describe 'GET similar_content' do
    before do
      @event = FactoryGirl.create :event
      @sim_content = FactoryGirl.create :content
      Content.any_instance.stub(:similar_content).with(@repo, 20).and_return([@sim_content])
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

  describe 'POST /contents/:id/moderate' do
     
    before do
      @content = FactoryGirl.create :content
      @user = FactoryGirl.create :user
      
      request.env['HTTP_AUTHORIZATION'] = "Token token=#{@user.authentication_token}, email=#{@user.email}"
    end

    it 'should queue flag notification email' do
      mailer_count = ActionMailer::Base.deliveries.count
      post :moderate, id: @content.id, flag_type: 'Inappropriate'
      expect(ActionMailer::Base.deliveries.count).to eq(mailer_count + 1)
    end

  end

end
