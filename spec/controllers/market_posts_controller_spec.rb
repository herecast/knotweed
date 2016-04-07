require 'spec_helper'

describe MarketPostsController, :type => :controller do
  before do
    @user = FactoryGirl.create :admin
    @market_post = FactoryGirl.create :market_post
    @region_location = FactoryGirl.create :location, id: Location::REGION_LOCATION_ID
    sign_in @user
  end

  describe "GET 'new'" do
    it "returns http success" do
      get 'new'
      expect(response).to be_success
    end
  end

  describe "POST 'create'" do
    it "redirect to market_posts index on success" do
      c = FactoryGirl.create :content
      post 'create', market_post: {
        content_attributes: {
          title: "hello",
          raw_content: "not blank"
        },
        cost: "$5"
      }
      expect(response.code).to eq("302")
    end
  end

  describe "GET 'edit'" do
    it "returns http success" do
      get 'edit', id: @market_post.id
      expect(response).to be_success
    end
  end

  describe 'GET index' do
    it 'returns http success' do
      get :index
      expect(response).to be_success
    end

    describe 'Search Filter' do
      before do
        # setup the search query hash
        @q = {id_in:  "", content_title_cont: "", pubdate_gteq: "", pubdate_lteq: "",
              content_authors_cont: "", content_repositories_id_eq: ""}

        # market_posts to filter against
        @market_post1 = FactoryGirl.create :market_post
        @market_post2 = FactoryGirl.create :market_post
        @market_post3 = FactoryGirl.create :market_post
        @market_post4 = FactoryGirl.create :market_post
      end

      it 'return selected titles' do
        @market_post4.title = 'ZZZZ';
        @market_post4.save
        @market_post3.title = 'ZZab';
        @market_post3.save

        @q[:content_title_cont] = 'ZZ'
        get :index, q: @q
        expect(assigns(:market_posts).length).to eq(2)
      end

      it 'return all market_posts' do
        get :index, q: @q
        expect(assigns(:market_posts).length).to eq(5)
      end
    end
  end

end
