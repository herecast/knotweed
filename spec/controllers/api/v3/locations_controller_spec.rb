require 'spec_helper'

describe Api::V3::LocationsController, :type => :controller do
  
  describe 'GET index', elasticsearch: true do
    before do
      FactoryGirl.create_list :location, 3
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
        FactoryGirl.create :location, city: 'Upper Valley', state: nil,  consumer_active: true
      end

      it "does not include the location named 'Upper Valley' "do 
        subject
        expect(assigns(:locations).select { |l| l.name.match 'Upper Valley' }.size).to eq(0)
      end
    end
  end

  describe 'GET closest', elasticsearch: true do
    let(:location) { FactoryGirl.create :location, consumer_active: true }
    let(:inactive_location) { FactoryGirl.create :location, consumer_active: false, lat: location.lat,
      long: location.long }
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
end
