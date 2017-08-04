require 'spec_helper'

describe Api::V3::LocationsController, :type => :controller do
  
  describe 'GET index', elasticsearch: true do
    before do
      FactoryGirl.create_list :location, 3, consumer_active: false
      @num_consumer_active = 2
      FactoryGirl.create_list :location, @num_consumer_active, consumer_active: true
    end

    subject { get :index }

    it 'has 200 status code' do
      subject
      expect(response.code).to eq('200')
    end

    it 'responds with consumer active locations' do
      subject
      expect(assigns(:locations).count).to eq(@num_consumer_active)
    end

    context do
      before do 
        FactoryGirl.create :location, city: 'Upper Valley', state: 'VT', consumer_active: true
      end

      it "does not include the location named 'Upper Valley' "do 
        subject
        expect(assigns(:locations).select { |l| l.name.match 'Upper Valley' }.size).to eq(0)
      end
    end
  end

  describe 'GET closest', elasticsearch: true do
    let(:location) { FactoryGirl.create :location, consumer_active: true }
    let(:inactive_location) { FactoryGirl.create :location, consumer_active: false, latitude: location.latitude,
      longitude: location.longitude }
    let(:count) { 5 }

    before do
      FactoryGirl.create_list :location, 6, consumer_active: true
    end

    subject { get :closest, id: location.id, count: count }

    it 'has 200 status code' do
      subject
      expect(response.code).to eq '200'
    end

    it 'responds with only consumer_active locations' do
      subject
      expect(assigns(:locations)).to_not include(inactive_location)
    end

    it 'responds with the specified number of locations' do
      subject
      expect(assigns(:locations).count).to eq count
    end
  end

  describe 'GET show' do
    let(:location) { FactoryGirl.create :location }

    subject! { get :show, id: location.id }

    it 'has 200 status code' do
      expect(response.code).to eq '200'
    end

    it 'responds with the location' do
      expect(assigns(:location)).to eq location
    end
  end

  describe 'GET locate' do
    context 'When nearest location is not consumer_active = true' do
      let!(:nearest) {
        FactoryGirl.create :location,
          consumer_active: false,
          latitude: 0.5,
          longitude: 0.5
      }
      let!(:nearest_active) {
        FactoryGirl.create :location,
          consumer_active: true,
          latitude: 0.8,
          longitude: 0.8
      }
      let!(:furthest) {
        FactoryGirl.create :location,
          consumer_active: true,
          latitude: 1.2,
          longitude: 1.2
      }

      subject {
        get :locate, coords: "0,0"
      }

      it 'returns nearest consumer_active location' do
        subject
        expect(assigns(:location)).to eql nearest_active
      end
    end
  end
end
