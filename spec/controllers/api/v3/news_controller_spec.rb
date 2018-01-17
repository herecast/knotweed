require 'spec_helper'

describe Api::V3::NewsController, :type => :controller do
  before do
    @news_cat = FactoryGirl.create :content_category, name: 'news'
  end

  describe 'GET index', elasticsearch: true do
    before do
      @original_organization = FactoryGirl.create :organization, org_type: 'Publication'
      @default_location = FactoryGirl.create :location, city: Location::DEFAULT_LOCATION
      @other_location = FactoryGirl.create :location, city: 'Another City'
      @third_location = FactoryGirl.create :location, city: 'Different Again'
      @user = FactoryGirl.create :user, location: @other_location
      FactoryGirl.create :content, content_category: @news_cat,
        locations: [@default_location], published: true, organization: @original_organization
      FactoryGirl.create :content, content_category: @news_cat,
        locations: [@other_location], published: true, organization: @original_organization
      FactoryGirl.create :content, content_category: @news_cat,
        locations: [@third_location], published: true, organization: @original_organization
      @consumer_app = FactoryGirl.create :consumer_app
      @consumer_app.organizations << @original_organization
      api_authenticate user: nil, consumer_app: @consumer_app
    end

    subject { get :index }

    it 'has 200 status code' do
      subject
      expect(response.code).to eq('200')
    end

    it_behaves_like "Location based index" do
      let(:content_type) { :news }
      let(:content_attributes) {
        {organization: @original_organization}
      }
    end

    context 'querying by organization name' do
      before do
        @org = FactoryGirl.create :organization
        @consumer_app.organizations << @org
        @org_and_loc_content = FactoryGirl.create :content, content_category: @news_cat,
          locations: [@default_location], organization: @org
      end

      subject! { get :index, format: :json, organization: @org.name }

      it 'should return content specific to that organization' do
        expect(assigns(:news)).to match_array([@org_and_loc_content])
      end
    end

    describe 'querying by organization_id' do
      before do
        @org = FactoryGirl.create :organization
        @consumer_app.organizations << @org
        @org_and_loc_content = FactoryGirl.create :content, content_category: @news_cat,
          locations: [@default_location], organization: @org
      end

      subject { get :index, format: :json, organization_id: @org.id }

      it 'should return content specific to that organization' do
        subject
        expect(assigns(:news)).to match_array([@org_and_loc_content])
      end

      context "with child organizations having content" do
        let(:child_org) { FactoryGirl.create(:organization, parent: @org, org_type: 'Blog') }
        let!(:child_org_content) {
          FactoryGirl.create :content, {
            organization: child_org,
            locations: [@default_location],
            content_category: @news_cat
          }
        }

        it 'returns the child org content with org content' do
          subject
          expect(assigns(:news)).to match_array([@org_and_loc_content, child_org_content])
        end
      end
    end

    context 'querying by named category;' do
      context 'with an existing "Sponsored Content" category;' do
        let!(:sponsored_cat) { FactoryGirl.create :content_category, name: 'Sponsored Content', parent: @news_cat }

        let!(:sponsored_content) { FactoryGirl.create :content, content_category: sponsored_cat, organization: Organization.first }
        let!(:not_sponsored) { FactoryGirl.create :content, content_category: @news_cat, organization: Organization.first }

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
        expect(assigns(:news).select{|c| c.content_category_id == @news_cat.id }.count).to eq(assigns(:news).count)
      end

      it 'should respond with news items in any location' do
        subject
        expect(assigns(:news).count).to eq(Content.where(content_category_id: @news_cat.id).count)
      end
    end

    context 'signed in' do
      before do
        api_authenticate user: @user
      end

      it 'should return news item that match any passed in location_id' do
        get :index, format: :json, location_id: @user.location.id
        expect(assigns(:news).select{|c| c.locations.include? @user.location }.count).to eq(assigns(:news).count)
      end

      it 'should return news item in any location when location_id is not sent' do
        subject
        expect(assigns(:news).count).to eq(Content.where(content_category_id: @news_cat.id).count)
      end
    end

    context 'with a search query' do
      before do
        @content = Content.where(content_category_id: @news_cat).first
      end

      subject { get :index, query: @content.title }

      it 'should return matching results' do
        subject
        expect(assigns(:news)).to match_array([@content])
      end
    end

    context 'with consumer app specified' do
      before do
        @content = Content.where(content_category_id: @news_cat).first
        @org = FactoryGirl.create :organization
        @content.update_attribute(:organization_id, @org.id)
        @consumer_app = FactoryGirl.create :consumer_app
        @consumer_app.organizations << @org
        api_authenticate consumer_app: @consumer_app
      end

      it 'should filter results by consumer app\'s organizations' do
        subject
        expect(assigns(:news)).to match_array([@content])
      end

      describe 'querying for an organization not associated with that consumer app' do
        before do
          @c2 = FactoryGirl.create :content, content_category: @news_cat,
            published: true
          @org2 = @c2.organization
        end

        subject! { get :index, organization: @org2.name }

        it 'should not return anything' do
          expect(JSON.parse(response.body)['news']).to be_empty
        end
      end
    end
  end

  describe 'GET show' do
    before do
      @news = FactoryGirl.create :content, content_category: @news_cat, published: true
    end

    subject { get :show, id: @news.id, format: :json }

    it 'has 200 status code' do
      subject
      expect(response.code).to eq('200')
    end

    it 'appropriately loads the news object' do
      subject
      expect(assigns(:news)).to eq(@news)
    end

    context 'signed in' do
      before do
        @repo = FactoryGirl.create :repository
        @user = FactoryGirl.create :user
        @consumer_app = FactoryGirl.create :consumer_app, repository: @repo
        @consumer_app.organizations << @news.organization
        api_authenticate user: @user, consumer_app: @consumer_app
      end

      context 'as an admin' do
        before { @user.add_role :admin }

        it 'should include the admin edit url in the response' do
          subject
          expect(JSON.parse(response.body)['news']['admin_content_url']).to be_present
        end
      end
    end

    describe 'for content that isn\'t news' do
      before { @c = FactoryGirl.create :content }

      it 'should respond with nothing' do
        get :show, id: @c.id
        expect(response.code).to eq '404'
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
        expect(assigns(:news)).to eq(@news)
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

      it { subject; expect(response.status).to eq 404 }
    end
  end

  describe 'POST #create' do
    let(:user) { FactoryGirl.create :user }
    before do
      api_authenticate user: user
    end

    let(:news_params) do
      {
        title: 'Title',
        subtitle: 'Subtitle',
        content: Faker::Lorem.paragraph,
        organization_id: FactoryGirl.create(:organization).id,
        published_at: Time.current,
        author_name: 'Some String Not The User'
      }
    end

    subject { post :create, {news: news_params} }

    context 'With locations' do
      let(:locations) { FactoryGirl.create_list(:location, 3) }
      before do
        news_params[:content_locations] = locations.map do |location|
          { location_id: location.slug }
        end
      end

      it 'allows nested content locations to be specified' do
        subject
        expect(response.status).to eql 201
        expect(Content.last.locations.to_a).to include *locations
      end

      context 'base locations' do
        before do
          news_params[:content_locations].each{|l| l[:location_type] = 'base'}
        end

        it 'allows nested location type to be specified as base' do
          subject
          expect(response.status).to eql 201
          expect(Content.last.base_locations.to_a).to include *locations
        end
      end
    end
  end

  describe 'PUT #update' do
    let(:user) { FactoryGirl.create :user }
    before do
      api_authenticate user: user
    end

    let(:news_params) do
      {
        title: 'Title',
        subtitle: 'Subtitle',
        content: Faker::Lorem.paragraph,
        organization_id: FactoryGirl.create(:organization).id,
        published_at: Time.current,
        author_name: 'Some String Not The User'
      }
    end

    let(:news) { FactoryGirl.create(:content, :news, created_by: user) }

    subject { put :update, {id: news.id, news: news_params} }

    it 'makes call to Facebook service' do
      allow(BackgroundJob).to receive(:perform_later).and_return true
      expect(BackgroundJob).to receive(:perform_later).with(
        'FacebookService', 'rescrape_url', news
      )
      subject
    end

    context "when pubdate is in future" do
      before do
        @news_params = news_params
        @news_params[:published_at] = Date.tomorrow
      end

      subject { put :update, {id: news.id, news: news_params} }

      it "does not call to Facebook service" do
        expect(BackgroundJob).not_to receive(:perform_later)
        subject
      end
    end

    context 'With locations' do
      let(:locations) { FactoryGirl.create_list(:location, 3) }
      before do
        news_params[:content_locations] = locations.map do |location|
          { location_id: location.slug }
        end
      end

      it 'allows nested content locations to be specified' do
        subject
        expect(response.status).to eql 200
        expect(Content.last.locations.to_a).to include *locations
      end

      context 'base locations' do
        before do
          news_params[:content_locations].each{|l| l[:location_type] = 'base'}
        end

        it 'allows nested location type to be specified as base' do
          subject
          expect(response.status).to eql 200
          expect(Content.last.base_locations.to_a).to include *locations
        end
      end
    end
  end
end
