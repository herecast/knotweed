require 'spec_helper'

describe Api::V2::EventsController do

  describe 'GET show' do
    before do
      @event = FactoryGirl.create :event
    end

    subject { get :show, format: :json, id: @event.id }

    it 'has a 200 status code' do
      subject
      response.code.should eq('200')
    end

  end

end
