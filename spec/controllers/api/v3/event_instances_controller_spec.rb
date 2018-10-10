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
      @event = FactoryGirl.create(:event)
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

    context 'when instance cannot be found' do
      it 'should return a 404 json response' do
        get :show, format: :json, id: 9009
        expect(response.status).to eql 404
        expect(response.headers['Content-Type']).to include 'application/json'
        expect(JSON.parse(response.body)).to match({"error" => an_instance_of(String)})
      end
    end

    describe 'ical_url' do
      before { allow(Figaro.env).to receive(:default_consumer_host).and_return("test.com") }
        

      it 'response should include ical url' do
        get :show, format: :json, id: @inst.id
        expect(JSON.parse(@response.body)['event_instance']['ical_url']).to eq "http://#{Figaro.env.default_consumer_host}/#{event_instances_ics_path(@inst.id)}"
      end
    end

    context "when related content has been removed" do
      before do
        @event = FactoryGirl.create(:event)
        @event.content.update_attribute(:removed, true)
        @instance = @event.next_or_first_instance
        allow(CreateAlternateContent).to receive(:call).and_return(@event.content)
      end

      subject { get :show, id: @instance.id }

      it "makes call to create alternate content" do
        expect(CreateAlternateContent).to receive(:call).with(
          @instance.event.content
        )
        subject
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
        @e_current = FactoryGirl.create(:event, start_date: Time.current + 1.minute).next_or_first_instance
      end

      context ' when start_date is passed' do
        it 'returns events on or after the start date' do
          get :index, {start_date: Date.current}
          result_ids = assigns(:event_instances).collect(&:id)
          expect(result_ids).to match_array([@e_current.id, @e_future.id])
        end
      end

      context 'when end_date is passed' do
        it 'should limit results by the end date' do
          get :index, end_date: Time.current + 1.minute
          result_ids = assigns(:event_instances).collect(&:id)
          expect(result_ids).to match_array([@e_current.id])
        end
      end


      describe "meta[:total]" do

        subject { get :index }

        it "returns total event instances matching search criteria" do
          subject
          payload = JSON.parse(response.body)
          expect(payload['meta']['total']).to eq 2
        end
      end
    end

    describe 'location_id filter' do
      let(:location_1) { FactoryGirl.create :location }
      let!(:event_location_1) {
        FactoryGirl.create :event,
          location_id: location_1.id
      }

      let(:location_2) { FactoryGirl.create :location }
      let!(:event_location_2) {
        FactoryGirl.create :content, :event,
          location_id: location_1.id
      }

      context 'location_id is not specified' do
        subject { get :index }

        it 'returns event instances from all locations' do
          subject
          result_ids = assigns(:event_instances).map(&:id)
          expect(result_ids).to match_array [
            event_location_1.event_instances.map(&:id),
            event_location_2.event_instances.map(&:id)
          ].flatten
        end
      end

      context 'location_id is specified' do
        subject { get :index, location_id: location_1.id }

        it 'returns event instances from the specified location' do
          subject
          results_ids = assigns(:event_instances).map(&:id)
          expect(results_ids).to include *[
            event_location_1.event_instances.map(&:id),
          ].flatten
        end
      end
    end

  end

end
