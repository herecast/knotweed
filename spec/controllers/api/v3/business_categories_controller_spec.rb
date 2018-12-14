require 'spec_helper'

describe Api::V3::BusinessCategoriesController, :type => :controller do
  describe 'GET index' do
    before do
      @bcs = FactoryGirl.create_list :business_category, 3
    end

    subject! { get :index, format: :json }

    it 'has 200 status code' do
      expect(response.code).to eq '200'
    end

    it 'loads the business categories' do
      expect(assigns(:business_categories)).to eq @bcs
    end
  end
end
