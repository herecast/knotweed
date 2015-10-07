require 'spec_helper'

describe Api::V3::NewsController do
  before do
    mixpanel_track_stub
    @news_cat = FactoryGirl.create :content_category, name: 'news'
  end

  describe 'GET index' do
    before do
      @default_location = FactoryGirl.create :location, city: Location::DEFAULT_LOCATION
      @other_location = FactoryGirl.create :location, city: 'Another City'
      @third_location = FactoryGirl.create :location, city: 'Different Again'
      @user = FactoryGirl.create :user, location: @other_location
      FactoryGirl.create_list :content, 3, content_category: @news_cat, 
        locations: [@default_location], published: true
      FactoryGirl.create_list :content, 5, content_category: @news_cat, 
        locations: [@other_location], published: true
      FactoryGirl.create_list :content, 4, content_category: @news_cat, 
        locations: [@third_location], published: true
    end

    subject { get :index, format: :json }

    it 'has 200 status code' do
      subject
      response.code.should eq('200')
    end

    it 'should allow querying by location_id' do
      get :index, format: :json, location_id: @third_location.id
      assigns(:news).select{|c| c.locations.include? @third_location }.count.should eq(assigns(:news).count)
    end

    context 'querying by publication name' do
      before do
        @pub = FactoryGirl.create :publication
        @pub_and_loc_content = FactoryGirl.create :content, content_category: @news_cat,
          locations: [@default_location], publication: @pub
        # this spec were causing a timing issue when run as part of the whole suite.
        # There may be a more holistic approach to solving this problem, but I'm not sure what it would be,
        # so I'm solving the problem for this spec by forcing an index.
        ThinkingSphinx::Test.index 'content_core', 'content_delta'
        ThinkingSphinx::Test.index 'publication_core'
        ThinkingSphinx::Test.index 'location_core'
      end

      subject! { get :index, format: :json, publication: @pub.name }

      it 'should return content specific to that publication' do
        assigns(:news).should eq([@pub_and_loc_content])
      end
    end

    context 'not signed in' do
      it 'should respond with news items' do
        subject
        assigns(:news).select{|c| c.content_category_id == @news_cat.id }.count.should eq(assigns(:news).count)
      end

      it 'should respond with news items in the default location' do
        subject
        assigns(:news).select{|c| c.locations.include? @default_location }.count.should eq(assigns(:news).count)
      end
    end

    context 'signed in' do
      before do
        api_authenticate user: @user
      end

      it 'should not automatically respond with news items in the signed in user\'s location' do
        subject
        assigns(:news).select{|c| c.locations.include? @user.location }.count.should eq(0)
      end

      it 'should return news item that match any passed in location_id' do
        get :index, format: :json, location_id: @user.location.id
        assigns(:news).select{|c| c.locations.include? @user.location }.count.should eq(assigns(:news).count)
      end

      it 'should return news item in the default location when location_id is not sent' do
        subject
        assigns(:news).select{|c| c.locations.include? @default_location }.count.should eq(assigns(:news).count)
      end
    end

  end

  describe 'GET show' do
    before do
      @news = FactoryGirl.create :content, content_category: @news_cat
    end

    subject { get :show, id: @news.id, format: :json }

    it 'has 200 status code' do
      subject
      response.code.should eq('200')
    end

    it 'appropriately loads the news object' do
      subject
      assigns(:news).should eq(@news)
    end

    it 'check comment_count' do
      comment_count = @news.comment_count
      subject
      news=JSON.parse(@response.body)
      news["news"]["comment_count"].should == comment_count
    end

    it 'should increment view count' do
      expect{subject}.to change{Content.find(@news.id).view_count}.from(0).to(1)
    end

  end

end
