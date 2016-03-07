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

    describe 'searching' do
      before do
        @bl = BusinessLocation.where(status: 'approved').first
      end

      subject { get :index, query: @bl.name }

      it 'should respond with the matching business location' do
        subject
        assigns(:venues).should eq [@bl]
      end

      context 'with autocomplete' do
        subject! { get :index, query: @bl.city, autocomplete: true }
        let(:response_hash) { JSON.parse response.body }

        it 'should render JSON with the root venue_locations' do
          response_hash['venue_locations'].should be_present
        end

        it 'should include the most commonly matched city, state pair as the first entry' do
          response_hash['venue_locations'][0].should eq "#{@bl.city}, #{@bl.state}"
        end
      end
    end

    context 'when user creates a private or new location' do
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
