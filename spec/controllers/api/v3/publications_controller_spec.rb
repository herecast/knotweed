require 'spec_helper'

describe Api::V3::PublicationsController do
  describe 'GET index' do
    before do
      @publication = FactoryGirl.create :publication
      @consumer_app = FactoryGirl.create :consumer_app
      @non_news_pub = FactoryGirl.create :publication
      @difft_app_pub = FactoryGirl.create :publication
      @news_cat = FactoryGirl.create :content_category, name: 'news'
      FactoryGirl.create(:content, publication: @publication,
        content_category: @news_cat)
      FactoryGirl.create(:content, publication: @difft_app_pub,
        content_category: @news_cat)
      @consumer_app.publications += [@publication, @non_news_pub]
      index
    end

    subject { get :index, format: :json }

    it 'has 200 status code' do
      subject
      response.code.should eq('200')
    end

    it 'only responds with publications associated with news content' do
      subject
      assigns(:publications).include?(@publication).should eq(true)
      assigns(:publications).include?(@difft_app_pub).should eq(true)
    end

    it 'filters by consumer app if requesting app is available' do
      get :index, format: :json, consumer_app_uri: @consumer_app.uri
      assigns(:publications).should eq([@publication])
    end

  end
end
