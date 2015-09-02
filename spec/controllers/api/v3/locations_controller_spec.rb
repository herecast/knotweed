require 'spec_helper'

describe Api::V3::LocationsController do
  
  describe 'GET index' do
    before do
      FactoryGirl.create_list :location, 3
      @num_consumer_active = 2
      FactoryGirl.create_list :location, @num_consumer_active, consumer_active: true
    end

    subject { get :index, format: :json }

    it 'has 200 status code' do
      subject
      response.code.should eq('200')
    end

    it 'responds with consumer active locations' do
      subject
      assigns(:locations).count.should eq(@num_consumer_active)
    end
  end

end
