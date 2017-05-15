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
      @event = FactoryGirl.create(:event, published: true)
      @inst = @event.next_or_first_instance
      schedule = FactoryGirl.create :schedule
      @inst.update_attribute(:schedule_id, schedule.id)
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

    describe 'record user visit' do
      before do
        @user = FactoryGirl.create :user
        api_authenticate user: @user
        @repo = FactoryGirl.create :repository
        @consumer_app = FactoryGirl.create :consumer_app, repository: @repo
      end

      subject { get :show, format: :json, id: @inst.id,
                  consumer_app_uri: @consumer_app.uri }

      it 'should queue record_user_visit if repository and user are present' do
        expect{subject}.to have_enqueued_job(BackgroundJob).with('DspService',
                        'record_user_visit', @event.content, @user, @repo)
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

      context "when event does not have a schedule" do
        it "returns false" do
          api_authenticate user: @user
          @inst.update_attribute(:schedule_id, nil)
          subject
          expect(can_edit).to be false
        end
      end
    end
  end

  describe 'GET ics' do
    before do
      @event = FactoryGirl.create :event
      @inst = @event.event_instances.first
    end

    it 'should contain ics data' do
      @request.env["HTTP_ACCEPT"] = "text/calendar"
      get :show, id: @inst.id
      expect(@response.body).to match /VCALENDAR/
      expect(@response.body).to match /DTSTART/
      expect(@response.body).to match /DTSTAMP/
      expect(@response.body).to match /VEVENT/
    end
  end

  describe 'GET index', elasticsearch: true do
    describe 'date filters' do
      before do
        @e_past = FactoryGirl.create(:event, start_date: 3.days.ago).next_or_first_instance
        @e_future = FactoryGirl.create(:event, start_date: 1.day.from_now).next_or_first_instance
        @e_current = FactoryGirl.create(:event, start_date: Date.current).next_or_first_instance
      end
      context ' when start_date is passed without category' do
        it 'returns events on the start date' do
          get :index
          expect(assigns(:event_instances)).to match_array([@e_current])
        end
      end

      context 'when end_date is passed' do
        it 'should limit results by the passed days_ahead' do
          get :index, days_ahead: 2
          expect(assigns(:event_instances)).to match_array([@e_current, @e_future])
        end
      end

      describe "meta[:total]" do

        subject { get :index }

        it "returns total event instances matching search criteria" do
          subject
          payload = JSON.parse(response.body)
          expect(payload['meta']['total']).to eq 1
        end
      end
    end

    context 'when category param present' do
      before do
        allow(GetEventsByCategories).to receive(:call).and_return []
        @category_param = { category: 'movies' }
      end

      subject { get :index, @category_param }

      it 'calls GetEventsByCategories with category param' do
        expect(GetEventsByCategories).to receive(:call).with(@category_param[:category], any_args)
        subject
      end
    end

    describe 'pagination' do
      before do
        @count = 5
        FactoryGirl.create_list :event, @count, start_date: Date.current
      end

      it 'should return paginated results' do
        get :index, per_page: @count - 1
        expect(assigns(:event_instances).length).to eq(@count -1)
      end
    end
  end

  describe "POST #create_impression" do
    context "when no event instance" do
      subject { post :create_impression, id: 5 }

      it "returns not_found status" do
        subject
        expect(response).to have_http_status :not_found
      end
    end

    context "when event instance is present" do
      before do
        @event = FactoryGirl.create :event
        @event.content.update_attribute :published, true
        @event_instance = @event.event_instances.first
      end

      subject { post :create_impression, id: @event_instance.id }

      context "when user is admin" do
        before do
          @user = FactoryGirl.create :user, skip_analytics: true
          api_authenticate user: @user
        end

        it "does not increment view count" do
          expect{ subject }.not_to change{
            @event_instance.reload.event.content.view_count
          }
        end

        it "returns accepted status" do
          subject
          expect(response).to have_http_status :accepted
        end
      end

      context "when user is not admin" do
        it "increments view count" do
          expect{ subject }.to change{
            @event_instance.reload.event.content.view_count
          }.by 1
        end

        it "returns accepted status" do
          subject
          expect(response).to have_http_status :accepted
        end
      end
    end
  end
end
