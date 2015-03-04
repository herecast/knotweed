require 'spec_helper'

# this stuff is annoyingly complex because of the relationship between events and
# event instances and how difficult it is to model with factories.
# The short answer is, the event factory is set up by default to create
# one corresponding event_instance with start_date defaulting to 1.week.from_now.
# You can customize start_date, subtitle, and description using these transient attributes:
# :start_date, :subtitle_override, :description_override
#
#   FactoryGirl.create(:event, start_date: 2.days.from_now, subtitle_override: "blargh")
#
# one important thing to note is that if you override just one entry of instance_attributes, 
# we lose the whole default hash -- which is currently just start date. So if you passed { subtitle: "Hello" },
# then your instance wouldn't have a start date.
describe Api::EventInstancesController do

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
      assigns(:event_instances).should == @featured_events.map{ |e| e.event_instances }.flatten
    end
  end

  describe "GET show" do
    # the json response here is quite complex, so we're rendering the view
    render_views

    before do
      @event = FactoryGirl.create :event
      @instance = @event.event_instances.first
    end

    subject { get :show, id: @instance.id, format: :json }

    it "has a 200 status code" do
      subject
      response.code.should eq("200")
    end

    it "should respond with the full event record and an array of instances" do
      subject
      resp = JSON.parse(response.body)
      resp["events"].count.should eq(1)
      event = resp["events"][0] # save some characters below
      event["id"].should eq(@instance.id) # ID passed to consumer app is that of the instance accessed
      event["content_id"].should eq(@event.content.id)
      event["event_instances"].count.should eq(1)
      Chronic.parse(event["event_instances"][0]["start_date"]).should eq(Chronic.parse(@instance.start_date.to_s))
    end

    describe "with more than one instance" do
      before do
        @inst2 = FactoryGirl.create :event_instance, event: @event
      end

      it "should respond with multiple instances in array" do
        subject
        event = JSON.parse(response.body)["events"][0]
        event["event_instances"].count.should eq(2)
      end
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
      assigns(:event_instances).count.should == 3
    end

    it "sorts events by start_date ASC" do
      e3 = FactoryGirl.create :event, start_date: Date.today
      e1 = FactoryGirl.create :event, start_date: 1.week.ago
      e2 = FactoryGirl.create :event, start_date: 1.week.from_now
      subject
      # the ".first" below is because we just created these and know they only have one event instance.
      assigns(:event_instances).should == [e1,e3,e2].map{ |e| e.event_instances.first }
    end

    it "should not return featured events unless specified" do
      e1 = FactoryGirl.create :event, featured: true
      e2 = FactoryGirl.create :event, featured: false
      subject
      assigns(:event_instances).should == [e2.event_instances.first]
    end

    it "should filter by repository if repository is specified" do
      events = FactoryGirl.create_list(:event, 3)
      r = FactoryGirl.create :repository
      r.contents << events[0].content
      get :index, format: :json, repository: r.dsp_endpoint
      assigns(:event_instances).should == [events[0].event_instances.first]
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
        assigns(:event_instances).should == [@e1.event_instances.first]
      end
      
      describe "if an event has multiple instances but only one falls in the date range" do
        before do
          @instance_2 = FactoryGirl.create(:event_instance, start_date: 2.weeks.ago, event: @e1)
        end

        it "should only return the instance in that range" do
          subject
          assigns(:event_instances).should == @e1.event_instances - [@instance_2]
        end
      end
    end
  end

end
