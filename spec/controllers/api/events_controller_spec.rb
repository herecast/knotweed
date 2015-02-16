require 'spec_helper'

describe Api::EventsController do

  describe "GET featured_events" do
    before do
      @featured_events = FactoryGirl.create_list(:event, 3, featured: true)
      @unfeatured_events = FactoryGirl.create_list(:event, 2, featured: false)
    end

    subject { get :featured_events, format: :json }

    it "has a 200 status code" do
      subject
      response.code.should eq("200")
    end

    it "responds with only upcoming featured events" do
      subject
      assigns(:events).should == @featured_events
    end
  end

  describe "GET index" do

    subject { get :index, format: :json }

    it "has a 200 status code" do
      subject
      response.code.should eq("200")
    end

    it "responds with events (and not regular content)" do
      FactoryGirl.create_list(:event, 3)
      FactoryGirl.create_list(:content, 2)
      subject
      assigns(:events).count.should == 3
    end

    it "sorts events by start_date ASC" do
      e3 = FactoryGirl.create :event, start_date: Date.today
      e1 = FactoryGirl.create :event, start_date: 1.week.ago
      e2 = FactoryGirl.create :event, start_date: 1.week.from_now
      subject
      assigns(:events).should == [e1,e3,e2]
    end

    it "should not return featured events unless specified" do
      e1 = FactoryGirl.create :event, featured: true
      e2 = FactoryGirl.create :event, featured: false
      subject
      assigns(:events).should == [e2]
    end

    it "should filter by repository if repository is specified" do
      events = FactoryGirl.create_list(:event, 3)
      r = FactoryGirl.create :repository
      r.contents << events[0].content
      get :index, format: :json, repository: r.dsp_endpoint
      assigns(:events).should == [events[0]]
    end

    describe "if params specifies a date range" do
      before do
        @e1 = FactoryGirl.create :event, start_date: Date.today
        @e2 = FactoryGirl.create :event, start_date: 1.week.ago
        @e3 = FactoryGirl.create :event, start_date: 1.week.from_now
      end

      subject { get :index, format: :json, start_date: 2.days.ago.to_s, end_date: 2.days.from_now.to_s }

      it "should only return events with start_date within that range" do
        subject
        assigns(:events).should == [@e1]
      end
    end
  end

  describe "GET show" do
    before do
      @event = FactoryGirl.create :event
    end
    
    subject { get :show, format: :json, id: @event.id }

    it "has a 200 status code" do
      subject
      response.code.should eq("200")
    end

    it "should assign the appropriate event instance variable" do
      subject
      assigns(:event).should == @event
    end

    describe "with repository specified via parameter" do
      before do
        @repo = FactoryGirl.create :repository
      end

      subject { get :show, format: :json, id: @event.id, repository: @repo.dsp_endpoint }

      it "should assign event to nil if the event is not in the repository" do
        subject
        assigns(:event).should == nil
      end

      it "should respond with the event if it does belong to the repository" do
        @repo.contents << @event.content
        subject
        assigns(:event).should == @event
      end

    end
  end

  describe "POST update" do
    before do
      @event = FactoryGirl.create :event
    end

    it "should update attributes on the event" do
      post :update, format: :json, id: @event.id, event: { event_description: "New Description" }
      response.code.should eq("200")
      @event.reload
      @event.event_description.should == "New Description"
    end

  end

end
