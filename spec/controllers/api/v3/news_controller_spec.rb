require 'spec_helper'

describe Api::V3::NewsController do
  before do
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
      index
    end

    subject { get :index }

    it 'has 200 status code' do
      subject
      response.code.should eq('200')
    end

    it 'should allow querying by location_id' do
      get :index, format: :json, location_id: @third_location.id
      assigns(:news).select{|c| c.locations.include? @third_location }.count.should eq(assigns(:news).count)
    end

    context 'querying by organization name' do
      before do
        @org = FactoryGirl.create :organization
        @org_and_loc_content = FactoryGirl.create :content, content_category: @news_cat,
          locations: [@default_location], organization: @org
        index
      end

      subject! { get :index, format: :json, organization: @org.name }

      it 'should return content specific to that organization' do
        assigns(:news).should eq([@org_and_loc_content])
      end
    end

    context 'querying by named category;' do
      context 'with an existing "Sponsored Content" category;' do
        let!(:sponsored_cat) { FactoryGirl.create :content_category, name: 'Sponsored Content', parent: @news_cat }

        let!(:sponsored_content) { FactoryGirl.create :content, content_category: sponsored_cat }
        let!(:not_sponsored) { FactoryGirl.create :content, content_category: @news_cat }

        before do
          index
        end

        subject! { get :index, format: :json, category: 'sponsored_content' }

        it 'param: category=sponsored_content returns records in the correct category only' do
          news = assigns(:news)
          expect(news).to include(sponsored_content)
          expect(news).to_not include(not_sponsored)
        end
      end
    end

    context 'not signed in' do
      it 'should respond with news items' do
        subject
        assigns(:news).select{|c| c.content_category_id == @news_cat.id }.count.should eq(assigns(:news).count)
      end

      it 'should respond with news items in any location' do
        subject
        assigns(:news).count.should eq(Content.where(content_category_id: @news_cat.id).count)
      end
    end

    context 'signed in' do
      before do
        api_authenticate user: @user
      end

      it 'should return news item that match any passed in location_id' do
        get :index, format: :json, location_id: @user.location.id
        assigns(:news).select{|c| c.locations.include? @user.location }.count.should eq(assigns(:news).count)
      end

      it 'should return news item in any location when location_id is not sent' do
        subject
        assigns(:news).count.should eq(Content.where(content_category_id: @news_cat.id).count)
      end
    end

    context 'with a search query' do
      before do
        @content = Content.where(content_category_id: @news_cat).first
      end

      subject { get :index, query: @content.title }

      it 'should return matching results' do
        subject
        assigns(:news).should eq([@content])
      end
    end

    context 'with consumer app specified' do
      before do
        @content = Content.where(content_category_id: @news_cat).first
        @org = @content.organization
        @consumer_app = FactoryGirl.create :consumer_app
        @consumer_app.organizations << @org
        api_authenticate consumer_app: @consumer_app
      end

      it 'should filter results by consumer app\'s organizations' do
        subject
        assigns(:news).should eq([@content])
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

    it 'should increment view count' do
      expect{subject}.to change{@news.reload.view_count}.from(0).to(1)
    end

    context 'signed in' do
      before do
        @repo = FactoryGirl.create :repository
        @user = FactoryGirl.create :user
        @consumer_app = FactoryGirl.create :consumer_app, repository: @repo
        @consumer_app.organizations << @news.organization
        stub_request(:post, /#{@repo.recommendation_endpoint}/)
        api_authenticate user: @user, consumer_app: @consumer_app
      end

      context 'as an admin' do
        before { @user.add_role :admin }

        it 'should include the admin edit url in the response' do
          subject
          JSON.parse(response.body)['news']['admin_content_url'].should be_present
        end
      end

      describe 'record_user_visit' do
        it 'should be called' do
          subject
          expect(WebMock).to have_requested(:post, /#{@repo.recommendation_endpoint}/)
        end
      end

    end

    describe 'for content that isn\'t news' do
      before { @c = FactoryGirl.create :content }

      it 'should respond with nothing' do
        get :show, id: @c.id
        response.code.should eq '204'
      end
    end
        

    context 'when requesting app has matching organizations' do
      before do
        organization = FactoryGirl.create :organization
        @news.organization = organization
        @news.save
        @consumer_app = FactoryGirl.create :consumer_app, organizations: [organization]
        api_authenticate consumer_app: @consumer_app
      end

      it 'should correctly load the content' do
        subject
        assigns(:news).should eq(@news)
      end
    end

    context 'when requesting app DOES NOT HAVE matching organizations' do
      before do
        organization = FactoryGirl.create :organization
        @news.organization = organization
        @news.save
        @consumer_app = FactoryGirl.create :consumer_app, organizations: []
        api_authenticate consumer_app: @consumer_app
      end

      it { subject; response.status.should eq 204 }
    end
  end

end
