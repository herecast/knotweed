require 'spec_helper'

describe Api::V3::BusinessCategoriesController do
  describe 'GET index' do
    before do
      @bcs = FactoryGirl.create_list :business_category, 3
    end

    subject! { get :index, format: :json }

    it 'has 200 status code' do
      response.code.should eq '200'
    end

    it 'loads the business categories' do
      assigns(:business_categories).should eq @bcs
    end
  end
end
