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
describe Api::V3::EventInstancesController, :type => :controller do

  describe 'GET show' do
    before do
      @event = FactoryGirl.create :event
      @inst = @event.next_or_first_instance
    end

    subject { get :show, format: :json, id: @inst.id }

    it 'should return the instance' do
      subject
      expect(assigns(:event_instance)).to eq(@inst)
    end

    it 'check comment_count' do
      comment_count = @inst.event.comment_count
      subject
      inst=JSON.parse(@response.body)
      expect(inst["event_instance"]["comment_count"]).to eq(comment_count)
    end

    it 'should increment view count' do
      expect{subject}.to change{Content.find(@inst.event.content.id).view_count}.from(0).to(1)
    end

    describe 'record user visit' do
      before do
        @event = FactoryGirl.create :event
        @user = FactoryGirl.create :user
        api_authenticate user: @user
        @repo = FactoryGirl.create :repository
        @consumer_app = FactoryGirl.create :consumer_app, repository: @repo
        stub_request(:post, /#{@repo.recommendation_endpoint}/)
      end

      it 'should call record_user_visit if repository and user are present' do
        get :show, id: @event.next_or_first_instance.id, format: :json,
          consumer_app_uri: @consumer_app.uri
        expect(WebMock).to have_requested(:post, /#{@repo.recommendation_endpoint}/)
      end
    end

    describe 'ical_url' do
      before do
        @consumer = FactoryGirl.create :consumer_app, uri: Faker::Internet.url
        api_authenticate consumer_app: @consumer
        get :show, format: :json, id: @inst.id
      end
      
      it 'response should include ical url' do
        expect(JSON.parse(@response.body)['event_instance']['ical_url']).to eq @consumer.uri + event_instances_ics_path(@inst.id)
      end
    end

    describe 'can_edit' do
      before do
        @location = FactoryGirl.create :location, city: 'Another City'
        @user = FactoryGirl.create :user, location: @location
        @event.content.update_attribute(:created_by, @user)
      end

      subject { get :show, id: @inst.id, format: :json}
      let(:can_edit) { JSON.parse(response.body)['event_instance']['can_edit'] }

      it 'should be true for content author' do
        api_authenticate user: @user
        subject 
        expect(can_edit).to eq(true)
      end
      it 'should be false for a different user' do
        @location = FactoryGirl.create :location, city: 'Another City'
        @different_user = FactoryGirl.create :user, location: @location
        api_authenticate user: @different_user
        subject 
        expect(can_edit).to eq(false)
      end
      it 'should be false when a user is not logged in' do
        subject 
        expect(can_edit).to eq(false)
      end

      context 'when user is admin' do
        before do
          @user = FactoryGirl.create :admin
          api_authenticate user: @user
        end
        it 'should be true' do
          subject
          expect(can_edit).to be_truthy
        end
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
      expect(@response.body).to match /VCALENDAR/
      expect(@response.body).to match /DTSTART/
      expect(@response.body).to match /DTSTAMP/
      expect(@response.body).to match /VEVENT/
    end
  end

  describe 'GET index' do
    describe 'date filters' do
      before do
        @e_past = FactoryGirl.create(:event, start_date: 3.days.ago).next_or_first_instance
        @e_future = FactoryGirl.create(:event, start_date: 1.week.from_now).next_or_first_instance
        @e_less_future = FactoryGirl.create(:event, start_date: 1.day.from_now).next_or_first_instance
        index
      end
      describe 'start_date' do
        it 'should search with start_date=today if no date_start is passed' do
          get :index
          expect(assigns(:event_instances)).to eql([@e_less_future, @e_future])
        end

        it 'should search by start date if it is passed' do
          get :index, date_start: 1.week.ago
          expect(assigns(:event_instances)).to eql([@e_past, @e_less_future, @e_future])
        end
      end

      describe 'end_date' do
        it 'should limit results by the passed date_end' do
          get :index, date_end: 2.days.from_now
          expect(assigns(:event_instances)).to eql([@e_less_future])
        end
      end
    end

    describe 'category' do
      before do
        @movie = FactoryGirl.create(:event, event_category: 'movies',
                                    start_date: 1.day.from_now).next_or_first_instance
        @wellness = FactoryGirl.create(:event, event_category: 'wellness', 
                                       start_date: 2.days.from_now).next_or_first_instance
        index
      end

      it 'should return results matching the category' do
        get :index, category: 'movies'
        expect(assigns(:event_instances)).to eql([@movie])
      end

      it 'should ignore category params that aren\'t whitelisted in Event::EVENT_CATEGORIES' do
        get :index, category: 'FAKE CATEGORY'
        expect(assigns(:event_instances)).to eql([@movie, @wellness])
      end
    end

    describe 'location' do
      before do
        @loc_with_no_events = FactoryGirl.create :location
        @parent_loc = FactoryGirl.create :location
        @child_loc = FactoryGirl.create :location, parents: [@parent_loc]
        @venue = FactoryGirl.create :business_location, city: @child_loc.city, state: @child_loc.state
        @event = FactoryGirl.create(:event, start_date: 2.days.from_now,
                                    venue: @venue).next_or_first_instance
        FactoryGirl.create_list :event, 3 # some other events
        index
      end

      it 'should search using matched city name and any child locations\' names' do
        get :index, location: @parent_loc.city
        expect(assigns(:event_instances)).to eql([@event])
      end

      it 'should return no results searching for a location with no events' do
        get :index, location: @loc_with_no_events.city
        expect(assigns(:event_instances)).to eql([])
      end
    end

    describe 'pagination' do
      before do
        @count = 5
        FactoryGirl.create_list :event, @count
        index
      end

      it 'should return paginated results' do
        get :index, per_page: @count - 1
        expect(assigns(:event_instances).length).to eq(@count -1)
      end
    end
  end
end
