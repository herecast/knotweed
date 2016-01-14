require 'spec_helper'

describe Api::V3::BusinessLocationsController do

  describe 'GET index' do
    before do
      FactoryGirl.create_list :business_location, 3, status: 'approved'
      FactoryGirl.create :business_location, status: 'new'
      FactoryGirl.create :business_location, status: 'private'
      index
    end

    subject { get :index, format: :json }

    it 'has 200 status code' do
      subject
      response.code.should eq('200')
    end

    it 'responds with approved business locations' do
      subject
      assigns(:venues).count.should eq BusinessLocation.where(status: 'approved').count
    end

    context 'when user creates a  private or new location' do
      before do
        @user = FactoryGirl.create :user
        @private_location = FactoryGirl.create :business_location, status: 'private', created_by: @user    
        @new_location = FactoryGirl.create :business_location, status: 'new', created_by: @user    
        FactoryGirl.create :business_location, status: 'approved'
        api_authenticate user: @user
        index
      end

      it 'it should be included in response' do
        subject
        assigns(:venues).include?(@private_location).should be_true
        assigns(:venues).include?(@new_location).should be_true
        assigns(:venues).count.should eq BusinessLocation.where(status: 'approved').count + 2
      end
    end
  end
end
