require 'spec_helper'

describe MarketPostsController do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  describe "GET 'index'" do
    it "returns http success" do
      get 'index'
      response.should be_success
    end
  end

  describe "GET 'show'" do
    it "returns http success" do
      pending 'debugging show action'
      get 'show'
      response.should be_success
    end
  end

  describe "GET 'new'" do
    it "returns http success" do
      get 'new'
      response.should be_success
    end
  end

  describe "GET 'create'" do
    it "returns http success" do
      get 'create'
      response.should be_success
    end
  end

  describe "GET 'edit'" do
    it "returns http success" do
      get 'edit'
      response.should be_success
    end
  end

  describe "GET 'update'" do
    it "returns http success" do
      pending 'debugging update action'
      get 'update'
      response.should be_success
    end
  end

=begin destroy action not implemented (yet, maybe never)
  describe "GET 'destroy'" do
    it "returns http success" do
      get 'destroy'
      response.should be_success
    end
  end
=end

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
      assigns(:market_posts).length.should == 2
    end

    it 'return all market_posts' do
      get :index, q: @q
      assigns(:market_posts).length.should == 4
    end
  end

end
