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
describe Api::V3::EventInstancesController do

=begin
  describe "GET index", sphinx: true do
    ThinkingSphinx::Test.run do

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
          sleep(0.5)
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
  end
=end

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

    it 'check comment_count' do
      comment_count = @inst.event.comment_count
      subject
      inst=JSON.parse(@response.body)
      inst["event_instance"]["comment_count"].should == comment_count
    end

    it 'should increment view count' do
      expect{subject}.to change{Content.find(@inst.event.content.id).view_count}.from(0).to(1)
    end

    context 'ical url' do
      before do
        @consumer = FactoryGirl.create :consumer_app, uri: Faker::Internet.url
        api_authenticate consumer_app: @consumer
        get :show, format: :json, id: @inst.id
      end
      
      it 'response should include ical url' do
        JSON.parse(@response.body)['event_instance']['ical_url'].should eq @consumer.uri + event_instances_ics_path(@inst.id)
      end
    end

  end

  describe 'GET ics' do
    before do
      @event = FactoryGirl.create :event
      @inst = @event.event_instances.first
    end

    subject! { get :show, format: :ics, id: @inst.id }

    it 'should contain ics data' do
      @response.body.should match /VCALENDAR/
      @response.body.should match /DTSTART/
      @response.body.should match /DTSTAMP/
      @response.body.should match /VEVENT/
    end
  end

  describe 'when user edits the content' do
    before do
      @location = FactoryGirl.create :location, city: 'Another City'
      @user = FactoryGirl.create :user, location: @location
      @event = FactoryGirl.create :event
      @event.content.update_attribute(:created_by, @user)
      @inst = @event.event_instances.first
    end

    subject { get :show, id: @inst.id, format: :json }

    it 'can_edit should be true for content author' do
      api_authenticate user: @user
      subject 
      JSON.parse(response.body)["event_instance"]["can_edit"].should == true
    end
    it 'can edit should be false for a different user' do
      @location = FactoryGirl.create :location, city: 'Another City'
      @different_user = FactoryGirl.create :user, location: @location
      api_authenticate user: @different_user
      subject 
      JSON.parse(response.body)["event_instance"]["can_edit"].should == false
    end
    it 'can_edit should be false when a user is not logged in' do
      subject 
      JSON.parse(response.body)["event_instance"]["can_edit"].should == false
    end

    context 'and user is admin' do
      before do
        @user = FactoryGirl.create :admin
        api_authenticate user: @user
      end
      it 'can_edit should be true' do
        subject
        JSON.parse(response.body)['event_instance']['can_edit'].should be_true
      end
    end
  end

  describe 'GET index' do
    before do
      @count = 3
      FactoryGirl.create_list :event, @count
      index
    end

    subject { get :index, format: :json }

    it 'should return all event instances' do
      subject
      assigns(:event_instances).count.should eq(@count)
    end
  
    context 'pagination' do
      it 'should return paginated results' do
        get :index, format: :json, per_page: @count - 1
        assigns(:event_instances).count.should eq(@count -1)
      end
    end
  end
end
