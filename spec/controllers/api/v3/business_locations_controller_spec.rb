require 'spec_helper'

describe Api::V3::BusinessLocationsController, :type => :controller do

  describe 'GET location' do
    let(:biz_location) do
      FactoryGirl.create :business_location
    end

    subject { get :location, format: :json, id: biz_location.id }

    context 'location exists' do
      let(:location) { FactoryGirl.build :location }

      before do
        allow_any_instance_of(BusinessLocation).to receive(:location)\
          .and_return(location)
      end

      it 'responds with a 200 status code' do
        subject
        expect(response.code).to eql "200"
      end

      it 'returns a json representation of location' do
        subject
        expect(response.body).to include_json({
          location: {
            id: location.slug,
            city: location.city,
            state: location.state
          }
        })
      end
    end

    context 'location does not exist' do
      it 'returns 404 status' do
        subject
        expect(response.code).to eql '404'
      end
    end
  end

  describe 'GET index', elasticsearch: true do
    before do
      FactoryGirl.create_list :business_location, 3, status: 'approved'
      FactoryGirl.create :business_location, status: 'new'
      FactoryGirl.create :business_location, status: 'private'
    end

    subject { get :index, format: :json }

    it 'has 200 status code' do
      subject
      expect(response.code).to eq('200')
    end

    it 'responds with approved business locations' do
      subject
      expect(assigns(:venues).count).to eq BusinessLocation.where(status: 'approved').count
    end

    describe 'searching' do
      before do
        @bl = BusinessLocation.where(status: 'approved').first
      end

      subject { get :index, query: @bl.name }

      it 'should respond with the matching business location' do
        subject
        expect(assigns(:venues)).to match_array [@bl]
      end

      context 'with autocomplete' do
        subject! { get :index, query: @bl.city, autocomplete: true }
        let(:response_hash) { JSON.parse response.body }

        it 'should render JSON with the root venue_locations' do
          expect(response_hash['venue_locations']).to be_present
        end

        it 'should include the most commonly matched city, state pair as the first entry' do
          expect(response_hash['venue_locations'][0]).to eq "#{@bl.city}, #{@bl.state}"
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
      end

      it 'it should be included in response' do
        subject
        expect(assigns(:venues).include?(@private_location)).to be_truthy
        expect(assigns(:venues).include?(@new_location)).to be_truthy
        expect(assigns(:venues).count).to eq BusinessLocation.where(status: 'approved').count + 2
      end
    end
  end
end
