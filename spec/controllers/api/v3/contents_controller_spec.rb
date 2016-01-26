require 'spec_helper'

describe Api::V3::ContentsController do
  before do
    @repo = FactoryGirl.create :repository
    @consumer_app = FactoryGirl.create :consumer_app, repository: @repo
    @org = FactoryGirl.create :organization
    @consumer_app.organizations = [@org]
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
      FactoryGirl.create_list :content, 5, content_category: @market_cat, 
        locations: [@default_location], published: true
      FactoryGirl.create_list :content, 5, content_category: @tott_cat,
        locations: [@default_location], published: true
      FactoryGirl.create_list :content, 5, content_category: @event_cat,
        locations: [@default_location], published: true
      FactoryGirl.create_list :content, 3, content_category: @market_cat, 
        locations: [@other_location]
      FactoryGirl.create_list :content, 3, content_category: @tott_cat, 
        locations: [@other_location]
      index
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

    context 'signed in' do
      before do
        api_authenticate user: @user
      end

      it 'has 200 status code' do
        subject
        response.code.should eq('200')
      end

      it 'should include talk items' do
        subject
        assigns(:contents).select{|c| c.content_category_id == @tott_cat.id }.count.should >0
      end

      it 'should return items in the user\'s location' do
        subject
        assigns(:contents).select{|c| c.locations.include? @other_location}.count.should eq(assigns(:contents).count)
      end

    end

  end

  describe 'GET related_promotion' do
    before do
      @content = FactoryGirl.create :content
      @related_content = FactoryGirl.create(:content)
      Promotion.any_instance.stub(:update_active_promotions).and_return(true)
      @promo = FactoryGirl.create :promotion, content: @related_content
      @pb = FactoryGirl.create :promotion_banner, promotion: @promo
      # avoid making calls to repo
      Content.any_instance.stub(:query_promo_similarity_index).and_return([])
    end

    subject { get :related_promotion, format: :json, 
              id: @content.id, consumer_app_uri: @consumer_app.uri }

    it 'has 200 status code' do
      subject
      response.code.should eq('200')
    end

    it 'should increment the impression count of the banner' do
      expect{subject}.to change{@pb.reload.impression_count}.by(1)
    end

    it 'should increment the daily impression count of the banner' do
      expect{subject}.to change{@pb.reload.daily_impression_count}.by(1)
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

    context 'with banner_ad_override' do
      before do
        @promo2 = FactoryGirl.create :promotion, content: FactoryGirl.create(:content)
        @pb2 = FactoryGirl.create :promotion_banner, promotion: @promo2
        @content.update_attribute :banner_ad_override, @promo2.id
      end

      it 'should respond with the banner specified by the banner_ad_override' do
        subject
        assigns(:banner).should eq @pb2
      end
    end

  end

  describe 'GET similar_content' do
    before do
      @content = FactoryGirl.create(:content)
      @content_id = @content.id
      # note, similar content is filtered by organization so we need to ensure this has
      # a organization that exists in the consumer app's list.
      @sim_content = FactoryGirl.create :content, organization: @org
      stub_request(:get, /recommend\/contextual\?contentid=/).
        to_return(:status => 200,
          :body => {'articles'=>[{ 'id' => "#{Content::BASE_URI}/#{@sim_content.id}" }]}.to_json,
          :headers => { 'Content-Type' => 'application/json;charset=UTF-8' })
    end

    subject { get :similar_content, format: :json,
        id: @content_id, consumer_app_uri: @consumer_app.uri }

    it 'has 200 status code' do
      subject
      response.code.should eq('200')
    end

    it 'responds with relation of similar content' do
      subject
      assigns(:contents).should eq([@sim_content])
    end

    context 'when similar content contains events with instances in the past or future' do
      before do
        @root_content = FactoryGirl.create :content, organization: @org
        @content = FactoryGirl.create :content, organization: @org
        other_content = FactoryGirl.create :content, organization: @org
        event = FactoryGirl.create :event, skip_event_instance: true, content: @content
        other_event = FactoryGirl.create :event, skip_event_instance: true, content: other_content
        FactoryGirl.create :event_instance, event: other_event, start_date: 1.week.ago
        FactoryGirl.create :event_instance, event: event, start_date: 1.month.ago
        FactoryGirl.create :event_instance, event: event, start_date: 1.week.from_now
        FactoryGirl.create :event_instance, event: event, start_date: 1.month.from_now
        @sim_content = [@content, other_content]
        Content.any_instance.stub(:similar_content).with(@repo, 20).and_return(@sim_content)
      end

      subject { get :similar_content, format: :json, id: @root_content.id, consumer_app_uri: @consumer_app.uri }

      it 'should response with events that have instances in the future' do
        subject
        assigns(:contents).should eq [@content]
      end
    end

    context 'for sponsored_content' do
      before do
        @content.content_category_id = FactoryGirl.create(:content_category, name: 'sponsored_content').id
        @some_similar_contents = FactoryGirl.create_list(:content, 3, organization: @org)
        @content.similar_content_overrides = @some_similar_contents.map{|c| c.id}
        @content.save
      end

      it 'should respond with the contents defined by similar_content_overrides' do
        subject
        assigns(:contents).should eq(@some_similar_contents)
      end
    end
  end

  describe 'POST /contents/:id/moderate' do
     
    before do
      @content = FactoryGirl.create :content
      @user = FactoryGirl.create :user
      
      api_authenticate user: @user
    end

    it 'should queue flag notification email' do
      mailer_count = ActionMailer::Base.deliveries.count
      post :moderate, id: @content.id, flag_type: 'Inappropriate'
      expect(ActionMailer::Base.deliveries.count).to eq(mailer_count + 1)
    end

  end

  describe 'GET dashboard' do
    subject { get :dashboard }

    context 'not signed in' do
      it 'has 401 status code' do
        subject
        response.code.should eq('401')
      end
    end

    context 'signed in' do
      before do
        @user = FactoryGirl.create :user
        api_authenticate user: @user
      end

      it 'has 200 status code' do
        subject
        response.code.should eq('200')
      end

      context 'with the user owning some content' do
        before do
          # because we're authenticated as the @user, created_by is actually set automatically here,
          # so we don't need to set it manually.
          @event = FactoryGirl.create :event
          FactoryGirl.create_list :market_post, 3
          FactoryGirl.create_list :comment, 2
        end

        it 'responds with the user\'s content' do
          subject
          expect(assigns(:contents)).to eq(Content.all)
        end

        it 'allows sorting by specified parameters' do
          get :dashboard, sort: 'pubdate DESC'
          expect(assigns(:contents).first).to eq(Content.order('pubdate DESC').first)
        end

      end
    end
  end

  describe 'GET ad_dashboard' do
    subject { get :ad_dashboard }
    
    context 'not signed in' do
      it 'has 401 status code' do
        subject
        response.code.should eq('401')
      end
    end

    context 'signed in' do
      before do
        @user = FactoryGirl.create :user
        api_authenticate user: @user
      end

      it 'has 200 status code' do
        subject
        response.code.should eq('200')
      end

      context 'with the user owning some content' do
        before do
          # because we're authenticated as the @user, created_by is actually set automatically here,
          # so we don't need to set it manually.
          @event = FactoryGirl.create :event
          FactoryGirl.create_list :market_post, 3
          FactoryGirl.create_list :comment, 2
          FactoryGirl.create :content # differs from regular dashboard here
        end

        it 'responds with the user\'s content' do
          subject
          expect(assigns(:contents)).to eq(Content.all)
        end

        it 'allows sorting by specified parameters' do
          get :dashboard, sort: 'pubdate DESC'
          expect(assigns(:contents).first).to eq(Content.order('pubdate DESC').first)
        end
      end
    end
  end

  describe 'GET /contents/:id/metrics' do
    before do
      @content = FactoryGirl.create :content
      @user = FactoryGirl.create :user
      api_authenticate user: @user
    end

    subject { get :metrics, id: @content.id }

    context 'without owning the content' do
      before do
        @content.update_attribute :created_by, nil
      end
      it 'should respond with 401' do
        subject
        expect(response.code).to eq('401')
      end
    end

    context 'as content owner' do
      before do
        @content.update_attribute :created_by, @user
      end

      it 'should respond with the content' do
        subject
        expect(assigns(:content)).to eq(@content)
      end
    end
  end
end
