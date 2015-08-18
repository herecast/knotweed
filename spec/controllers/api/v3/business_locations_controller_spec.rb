require 'spec_helper'

describe Api::V3::BusinessLocationsController do

  describe 'GET index' do
    before do
      FactoryGirl.create_list :business_location, 3
    end

    subject { get :index, format: :json }

    it 'has 200 status code' do
      subject
      response.code.should eq('200')
    end

    it 'responds with business location objects as venues' do
      subject
      assigns(:venues).count.should eq(BusinessLocation.count)
    end
  end
end


