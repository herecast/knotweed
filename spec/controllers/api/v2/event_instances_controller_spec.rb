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
describe Api::V2::EventInstancesController do

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
    
    describe 'if params specifies a category' do
      before do
        FactoryGirl.create_list :event, 2, event_category: Event::EVENT_CATEGORIES[0]
        FactoryGirl.create_list :event, 3, event_category: Event::EVENT_CATEGORIES[1]
      end

      it 'should not filter by category if the param is not an enumerated value' do
        get :index, format: :json, category: 'woof woof'
        assigns(:event_instances).count.should == 5
      end

      it 'should filter by category if a valid category is specified' do
        get :index, format: :json, category: Event::EVENT_CATEGORIES[0]
        assigns(:event_instances).count.should == 2
      end

      it 'should match string parameter to symbol value' do
        yardsales = FactoryGirl.create :event, event_category: :yard_sales # note if event categories change, we may need to change this
        get :index, format: :json, category: 'Yard sales'
        assigns(:event_instances).should eq([yardsales.event_instances.first])
      end
    end

    describe "if params specifies a date range" do
      before do
        @e1 = FactoryGirl.create :event, start_date: Date.today
        @e2 = FactoryGirl.create :event, start_date: 1.week.ago
        @e3 = FactoryGirl.create :event, start_date: 1.week.from_now
      end

      subject { get :index, format: :json, date_start: 2.days.ago.to_s, date_end: 2.days.from_now.to_s }

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

  describe 'GET show' do
    before do
      @event = FactoryGirl.create :event
      @inst = @event.event_instances.first
    end

    subject { get :show, format: :json, id: @inst.id }

    it 'should return the instance' do
      subject
      assigns(:event_instance).should eq(@inst)
    end

  end

end
