require 'spec_helper'

describe BusinessLocationsController, :type => :controller do
  before do
    @user = FactoryGirl.create :admin
    @business_location = FactoryGirl.create :business_location
    sign_in @user
    request.env['HTTP_REFERER'] = 'where_i_came_from'
  end

  describe "GET 'index'" do
    it 'returns http success' do
      get 'index'
      expect(response).to be_success
    end
  end

  describe "GET 'new'" do
    it 'returns http success' do
      get 'new'
      expect(response).to be_success
    end
  end

  describe "POST 'create'" do
    it 'returns http success' do
      FactoryGirl.create :business_location
      expect(response).to be_success
    end
  end

  describe "GET 'edit'" do
    it 'returns http success' do
      get 'edit', id: @business_location.id
      expect(response).to be_success
    end
  end

  describe "PUT 'update'" do
    subject { put :update, { id: @business_location.to_param, business_location: params} }
    describe 'with valid params' do
      let(:params) do
        { name: 'Another string'
        }
      end
      it 'updates the requested venue' do
        subject
        @business_location.reload
        expect(@business_location.name).to eq(params[:name])
      end
      it 'redirect to business_locations' do
        subject
        #response.should be_success
        expect(response).to redirect_to(business_locations_path)
      end
    end
  end

  describe "GET 'destroy'" do
    subject { delete :destroy, { id: @business_location.to_param} }
    it 'redirect to back' do
      subject
      expect(response).to redirect_to 'where_i_came_from'
    end
  end

end
