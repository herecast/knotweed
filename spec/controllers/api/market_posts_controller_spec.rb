require 'spec_helper'

describe Api::MarketPostsController do

  describe "GET 'show'" do
    before do
      @market_post = FactoryGirl.create(:market_post)
      @market_post.content.update_attribute :published, true
    end

    it "returns http success" do
      get :show, format: :json, id: @market_post.id
      response.should be_success
    end

    it "responds with nil if the associated content isn't marked published and repository is passed" do
      @market_post.content.update_attribute :published, false
      get :show, format: :json, id: @market_post.id, repository: "http://fake-repo.com"
      assigns(:market_post).should eq(nil)
    end

  end
      

  describe "GET 'index'" do
    it "returns http success" do
      get :index, format: :json
      response.should be_success
    end

    it "returns the appropriate set of contents" do
      # create a couple market posts, a couple content that are "external only,"
      # and a couple that are neither
      market_posts = FactoryGirl.create_list :market_post, 3
      pub = FactoryGirl.create :publication
      ext_category = FactoryGirl.create :content_category
      pub.external_categories << ext_category
      ext_contents = FactoryGirl.create_list :content, 2, 
        content_category: ext_category, publication: pub
      other_content = FactoryGirl.create :content, publication: pub
      get :index, format: :json
      market_posts.each do |mp|
        assigns(:contents).should include(mp.content)
      end
      ext_contents.each do |c|
        assigns(:contents).should include(c)
      end
      assigns(:contents).should_not include(other_content)
    end
  end

end
