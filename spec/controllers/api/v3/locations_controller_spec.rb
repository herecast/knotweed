require 'spec_helper'

describe Api::V3::LocationsController do
  
  describe 'GET index' do
    before do
      FactoryGirl.create_list :location, 3
      @num_consumer_active = 2
      FactoryGirl.create_list :location, @num_consumer_active, consumer_active: true
    end

    subject { get :index }

    it 'has 200 status code' do
      subject
      response.code.should eq('200')
    end

    it 'responds with consumer active locations' do
      subject
      assigns(:locations).count.should eq(@num_consumer_active)
    end

    context 'with a query parameter' do
      before do
        @loc1 = FactoryGirl.create :location, consumer_active: true, city: 'search for me'
        @loc2 = FactoryGirl.create :location, consumer_active: false, city: 'shouldnotfind'
        index
      end
      
      it 'should return consumer active search results' do
        get :index, query: 'search'
        expect(assigns(:locations)).to eq([@loc1])
      end

      it 'should not return search results that are not consumer active' do
        get :index, query: 'shouldnotfind'
        expect(assigns(:locations)).to eq([])
      end

    end
  end

end
