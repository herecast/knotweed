require 'spec_helper'

describe Api::V3::OrganizationsController do
  describe 'GET index' do
    before do
      @organization = FactoryGirl.create :organization
      @consumer_app = FactoryGirl.create :consumer_app
      @non_news_org = FactoryGirl.create :organization
      @difft_app_org = FactoryGirl.create :organization
      @news_cat = FactoryGirl.create :content_category, name: 'news'
      FactoryGirl.create(:content, organization: @organization,
        content_category: @news_cat)
      FactoryGirl.create(:content, organization: @difft_app_org,
        content_category: @news_cat)
      @consumer_app.organizations += [@organization, @non_news_org]
      index
    end

    subject { get :index, format: :json }

    it 'has 200 status code' do
      subject
      response.code.should eq('200')
    end

    it 'only responds with organizations associated with news content' do
      subject
      assigns(:organizations).include?(@organization).should eq true
      assigns(:organizations).include?(@non_news_org).should eq false
      assigns(:organizations).include?(@difft_app_org).should eq true
    end

    it 'filters by consumer app if requesting app is available' do
      get :index, format: :json, consumer_app_uri: @consumer_app.uri
      assigns(:organizations).should eq([@organization])
    end

  end
end
