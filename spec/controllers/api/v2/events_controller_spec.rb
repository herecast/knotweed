require 'spec_helper'

describe Api::V2::EventsController do

  describe 'GET show' do
    before do
      @event = FactoryGirl.create :event
    end

    it 'should respond with the event' do
      get :show, format: :json, id: @event.id
      response.code.should eq('200')
      assigns(:event).should eq @event
    end

  end

  describe 'POST create' do
    before do
      @venue = FactoryGirl.create :business_location
      @current_user = FactoryGirl.create :user
      @listserv = FactoryGirl.create :listserv
      @event_attrs = {
        category: Event::EVENT_CATEGORIES[0],
        contact_email: 'test@test.com',
        contact_phone: '888-888-8888',
        content: 'Hello this is test.',
        cost: '$25',
        cost_type: 'free',
        event_instances: [
          {
            subtitle: 'fake subtitle',
            starts_at: '2015-05-28T13:00:00-04:00',
            ends_at: '2015-05-28T20:00:00-04:00'
          }, {
            subtitle: 'different fake subtitle',
            starts_at: '2015-05-29T13:00:00-04:00'
          }
        ],
        event_url: 'http://www.google.com',
        social_enabled: true,
        title: 'This is the title',
        venue_id: @venue.id,
        listserv_ids: [@listserv.id]
      }
    end

    subject { post :create, format: :json, event: @event_attrs, current_user_id: @current_user.id }

    it 'should create an event with a valid submission' do
      subject
      response.code.should eq('201')
      Event.count.should eq(1)
      assigns(:event).event_instances.count.should eq(2)
      assigns(:event).content.title.should eq(@event_attrs[:title])
    end

    it 'should respond with 422 unprocessable entity if event creation fails due to validation' do
      invalid_attrs = @event_attrs.dup
      invalid_attrs[:event_instances] = []
      post :create, format: :json, event: invalid_attrs, current_user_id: @current_user.id
      Event.count.should eq(0)
      response.code.should eq('422')
    end

    it 'should respond with a 401 if no current_user_id is provided' do
      post :create, format: :json, event: @event_attrs
      response.code.should eq('401')
      Event.count.should eq(0)
    end

    it 'should assign the event to the current api user\'s location' do
      subject
      assigns(:event).content.location_ids.should eq([@current_user.location_id])
    end

    it 'should assign the event to user location AND upper valley if extended_reach_enabled is true' do
      ext_reach_attrs = @event_attrs.dup
      ext_reach_attrs[:extended_reach_enabled] = true
      # ensure that the region location actually exists...
      FactoryGirl.create :location, id: Location::REGION_LOCATION_ID
      post :create, format: :json, event: ext_reach_attrs, current_user_id: @current_user.id
      assigns(:event).content.location_ids.count.should eq(2)
      assigns(:event).content.location_ids.include?(@current_user.location_id).should be_true
      assigns(:event).content.location_ids.include?(Location::REGION_LOCATION_ID).should be_true
    end

    it 'creates a venue with venue attributes given (instead of venue_id)' do
      with_venue_attrs = @event_attrs.dup
      with_venue_attrs[:venue] = {
        name: "Norwich Historical Society",
        address: "34 Elm Street",
        city: "Norwich",
        state: "VT"
      }
      with_venue_attrs.delete :venue_id
      post :create, format: :json, event: with_venue_attrs, current_user_id: @current_user.id
      BusinessLocation.count.should eq(2)
      assigns(:event).venue.should_not eq(@venue)
      assigns(:event).venue.name.should eq(with_venue_attrs[:venue][:name])
    end

  end
 
  describe 'POST moderate' do
    before do
      @event = FactoryGirl.create :event
      @user = FactoryGirl.create :user
    end

    it 'should queue flag notification email' do
      post :moderate, id: @event.id, current_user_id: @user.id,
        flag_type: 'Inappropriate'
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end

  end

end
