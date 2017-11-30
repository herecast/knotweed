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

    context 'when instance cannot be found' do
      it 'should return a 404 json response' do
        get :show, format: :json, id: 9009
        expect(response.status).to eql 404
        expect(response.headers['Content-Type']).to include 'application/json'
        expect(JSON.parse(response.body)).to match({"error" => an_instance_of(String)})
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

    context "when related content has been removed" do
      before do
        @event = FactoryGirl.create(:event, published: true)
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
        @e_past = FactoryGirl.create(:event, published: true, start_date: 3.days.ago).next_or_first_instance
        @e_future = FactoryGirl.create(:event, published: true, start_date: 1.day.from_now).next_or_first_instance
        @e_current = FactoryGirl.create(:event, published: true, start_date: Time.current + 1.minute).next_or_first_instance
      end

      context ' when start_date is passed' do
        it 'returns events on or after the start date' do
          get :index, {start_date: Date.current}
          result_ids = assigns(:event_instances).collect(&:id)
          expect(result_ids).to match_array([@e_current.id, @e_future.id])
        end
      end

      context 'when end_date is passed' do
        it 'should limit results by the passed days_ahead' do
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

      describe 'Paging' do
        context 'Given start_date, page, per_page' do
          let(:start_date) { 3.days.from_now - 1.hour }
          let(:page) { 2 }
          let(:per_page) { 1 }

          subject { get :index, start_date: start_date, page: page, per_page: 1 }

          before do
            FactoryGirl.create_list :event_instance, 2,
              published: true,
              start_date: 3.days.from_now

            @records_for_page = FactoryGirl.create_list :event_instance, 3,
              published: true,
              start_date: 4.days.from_now

            FactoryGirl.create_list :event_instance, 3,
              published: true,
              start_date: 5.days.from_now
          end

          it 'should page by day, not records' do
            subject
            expect(assigns(:event_instances).length).to eql 3
            expect(assigns(:event_instances).map(&:id)).to include(*@records_for_page.map(&:id))

            expect(JSON.parse(response.body)['meta']['total_pages']).to eql 3
          end
        end
      end
    end

    describe 'location_id filter' do
      let(:location_1) { FactoryGirl.create :location }
      let!(:event_location_1) {
        FactoryGirl.create :event,
          published: true,
          base_locations: [location_1],
          start_date: 3.hours.from_now
      }
      let!(:event_location_3) {
        FactoryGirl.create :event,
          published: true,
          about_locations: [location_1],
          start_date: 3.hours.from_now
      }

      let(:location_2) { FactoryGirl.create :location }
      let!(:event_location_2) {
        FactoryGirl.create :event,
          published: true,
          base_locations: [location_2],
          start_date: 3.hours.from_now
      }

      context 'location_id is not specified' do
        subject { get :index }

        it 'returns event instances from all locations' do
          subject
          result_ids = assigns(:event_instances).map(&:id)
          expect(result_ids).to match [
            event_location_1.event_instances.map(&:id),
            event_location_3.event_instances.map(&:id),
            event_location_2.event_instances.map(&:id)
          ].flatten
        end
      end

      context 'location_id is specified' do
        subject { get :index, location_id: location_1.slug }

        it 'returns event instances from the specified location' do
          subject
          results_ids = assigns(:event_instances).map(&:id)
          expect(results_ids).to include *[
            event_location_1.event_instances.map(&:id),
            event_location_3.event_instances.map(&:id)
          ].flatten
        end

        context 'with radius specified' do
          let(:radius) { 20 }
          let!(:near_event) {
            FactoryGirl.create :event,
              published: true,
              locations: [
                FactoryGirl.create(:location, coordinates: Geocoder::Calculations.random_point_near(
                  location_1,
                  19, units: :mi
                )),
                FactoryGirl.create(:location)
              ]
          }

          it 'returns event instances located within radius' do
            get :index, location_id: location_1.slug, radius: radius, days_ahead: 365
            results_ids = assigns(:event_instances).map(&:id)
            expect(results_ids).to include *near_event.event_instances.map(&:id)
          end

          context 'My town only' do
            let!(:near_event_my_town_only) {
              FactoryGirl.create :event,
                title: 'near, my-town-only',
                locations: [
                  FactoryGirl.create(:location, coordinates: Geocoder::Calculations.random_point_near(
                    location_1,
                    19, units: :mi
                  ))
                ]
            }

            before do
              near_event_my_town_only.content.content_locations.each do |cl|
                cl.update location_type: 'base'
              end
              EventInstance.reindex
            end

            it 'does not return events which are within radius, but my town only' do
              get :index, location_id: location_1.slug, radius: radius, days_ahead: 365
              expect(assigns(:event_instances).results).to_not include *near_event_my_town_only.event_instances
            end
          end
        end
      end
    end

  end

end
