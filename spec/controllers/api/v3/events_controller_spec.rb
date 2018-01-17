require 'spec_helper'

describe Api::V3::EventsController, :type => :controller do
  before do
    @venue = FactoryGirl.create :business_location
    @current_user = FactoryGirl.create :user
    @listserv = FactoryGirl.create :listserv
    api_authenticate user:  @current_user
    @event_attrs = {
      contact_email: 'test@test.com',
      contact_phone: '888-888-8888',
      content: 'Hello this is test.',
      cost: '$25',
      cost_type: 'free',
      schedules: [
        {
          subtitle: 'fake subtitle',
          starts_at: '2015-05-28T13:00:00-04:00',
          ends_at: '2015-05-28T20:00:00-04:00',
          repeats: 'once',
          presenter_name: 'Bob Jones'
        }
      ],
      event_url: 'http://www.google.com',
      social_enabled: true,
      title: 'This is the title',
      venue_id: @venue.id,
      listserv_ids: [@listserv.id],
      registration_deadline: 1.day.from_now,
      registration_url: 'http://www.google.com',
      registration_phone: '888-888-8888',
      registration_email: 'test@fake.com',
      promote_radius: 10,
      ugc_base_location_id: FactoryGirl.create(:location).slug
    }
  end

  describe 'GET show' do
    before do
      @event = FactoryGirl.create :event
    end

    subject { get :show, format: :json, id: @event.id }

    it 'should respond with the event' do
      subject
      expect(response.code).to eq('200')
      expect(assigns(:event)).to eq @event
    end
    context 'when requesting app has matching organizations' do
      before do
        organization = FactoryGirl.create :organization
        @event.content.organization = organization
        @event.save
        @consumer_app = FactoryGirl.create :consumer_app, organizations: [organization]
        api_authenticate consumer_app: @consumer_app
      end
      it do
        subject
        expect(response.status).to eq 200
        expect(JSON.parse(response.body)['event']['id']).to eq(@event.id)
      end
    end
    context 'when requesting app DOES NOT HAVE matching organizations' do
      before do
        organization = FactoryGirl.create :organization
        @event.content.organization = organization
        @event.save
        @consumer_app = FactoryGirl.create :consumer_app, organizations: []
        api_authenticate consumer_app: @consumer_app
      end
      it { subject; expect(response.status).to eq 204 }
    end
  end

  describe 'GET index', elasticsearch: true do
    let(:organization) { FactoryGirl.create :organization }

    let(:consumer_app) {
      FactoryGirl.create :consumer_app,
        organizations: [organization]
    }

    let(:headers) { {
      'ACCEPT' => 'application/json',
      'Consumer-App-Uri' => consumer_app.uri
    } }

    it_behaves_like "Location based index" do
      let(:content_type) { :event }
    end
  end

  describe 'PUT update' do
    before do
      @event = FactoryGirl.create :event, created_by: @current_user
      @schedule = FactoryGirl.create :schedule, event: @event
      @attrs_for_update = @event.attributes.select do |k,v|
        ![:links, :sponsor, :sponsor_url, :featured, :id,
         :created_at, :updated_at].include? k.to_sym
      end
      @attrs_for_update[:title] = 'Changed the title!'
      @attrs_for_update[:content] = @event.content.raw_content
      schedule_changes = @schedule.to_ux_format.merge({
        subtitle: 'changed subtitle!',
        presenter_name: 'Bob Loblaw'
      })
      @attrs_for_update[:schedules] = [schedule_changes]
      @attrs_for_update[:cost] = '$100'
      @attrs_for_update[:registration_url] = 'http://boogle.com'
      @different_user = FactoryGirl.create :user
    end

    subject { put :update, event: @attrs_for_update, id: @event.id }

    context 'should not allow update if current_api_user does not match created_by' do
      before do
        api_authenticate user: @different_user
      end
      it do
      	put :update, event: @attrs_for_update, id: @event.id
      	expect(response.code).to eq('403')
      end
    end

    context 'with invalid attributes' do
      before do
        @attrs_for_update[:title] = ''
      end

      it 'should respond with errors' do
        subject
        expect(JSON.parse(response.body).has_key?('errors')).to be_truthy
      end

      it 'should respond with 422' do
        subject
        expect(response.code).to eq '422'
      end
    end

    context 'with consumer_app / repository' do
      before do
        @repo = FactoryGirl.create :repository
        @consumer_app = FactoryGirl.create :consumer_app, repository: @repo
        api_authenticate user: @user, consumer_app: @consumer_app
        stub_request(:post, /.*/)
      end

      it 'should queue the content to be published' do
        expect{subject}.to have_enqueued_job(PublishContentJob)
      end
    end

    describe 'with an image' do
      before do
        @file = fixture_file_upload('/photo.jpg', 'image/jpg')
      end

      subject { put :update, id: @event.id, event: { image: @file } }

      it 'should create a new Image record' do
        expect{subject}.to change{Image.count}.by(1)
      end

      it 'should destroy all other images associated with the event' do
        @image = FactoryGirl.create :image, imageable: @event.content
        expect{subject}.not_to change{Image.count}
      end
    end

    it 'should update the event attributes' do
      subject
      expect(response.code).to eq('200')
      @event.reload
      expect(@event.cost).to eq(@attrs_for_update[:cost])
      expect(@event.registration_url).to eq(@attrs_for_update[:registration_url])
    end

    it 'makes call to Facebook service' do
      allow(BackgroundJob).to receive(:perform_later).and_return true
      expect(BackgroundJob).to receive(:perform_later).with(
        'FacebookService', 'rescrape_url', @event.content
      )
      subject
    end

    it 'should update the associated content attributes' do
      subject
      @event.reload
      expect(@event.content.title).to eq(@attrs_for_update[:title])
    end

    it 'should update the associated event instance attributes' do
      subject
      @event.reload
      expect(@event.event_instances.first.subtitle_override)
        .to eq(@attrs_for_update[:schedules][0][:subtitle])
      expect(@event.event_instances.first.presenter_name)
        .to eq(@attrs_for_update[:schedules][0][:presenter_name])
    end

      context 'with promotion location information' do
        let(:radius) { 20 }
        let(:location) { FactoryGirl.create(:location) }
        before do
          @attrs_for_update[:promote_radius] = radius
          @attrs_for_update[:ugc_base_location_id] = location.slug
        end

        it 'runs content through UpdateContentLocations process' do
          expect(UpdateContentLocations).to receive(:call).with(@event.content, promote_radius: radius, base_locations: [location])

          subject
        end
      end

  end

  describe 'PUT by admin' do
    before do
      @admin = FactoryGirl.create :admin
      @user = FactoryGirl.create :user
      @event = FactoryGirl.create :event, created_by: @user, title: Faker::Book.title
      @to_change = {title: Faker::Book.title, schedules: {}}
      api_authenticate user: @admin
    end

    subject { put :update, event: @to_change, id: @event.id }

    it 'should update changed fields' do
      subject
      expect(assigns(:event).content.title).to eq @to_change[:title]
      expect(assigns(:event).content.updated_by).to eq @admin
      expect(assigns(:event).content.created_by).to eq @user
    end
  end

  describe 'POST create' do
    before do
      allow(BitlyService).to receive(:create_short_link).with(any_args).and_return('http://bit.ly/12345')

      @event_attrs[:ugc_job] = "Schedule a yoga class"
    end

    subject { post :create, format: :json, event: @event_attrs, current_user_id: @current_user.id }

    it 'should create an event with a valid submission' do
      subject
      expect(response.code).to eq('201')
      expect(Event.count).to eq(1)
      expect(assigns(:event).event_instances.count).to eq(1)
      expect(assigns(:event).content.title).to eq(@event_attrs[:title])
      expect(assigns(:event).content.ugc_job).to eq(@event_attrs[:ugc_job])
    end

    context 'should respond with a 401 if user is not authenticated' do
      before { api_authenticate success: false }
      it do
      	post :create, format: :json, event: @event_attrs
      	expect(response.code).to eq('401')
      	expect(Event.count).to eq(0)
      end
    end

    context "when user does not flag wants_to_advertise" do
      it "does not send an email to admin" do
        mail = double()
        expect(mail).not_to receive(:deliver_later)
        expect(AdMailer).not_to receive(:event_adveritising_request)
        subject
      end
    end

    context 'with consumer_app / repository' do
      before do
        @repo = FactoryGirl.create :repository
        @consumer_app = FactoryGirl.create :consumer_app, repository: @repo
        api_authenticate user: @user, consumer_app: @consumer_app
        stub_request(:post, /.*/)
      end

      it 'should queue the content to be published' do
        expect{subject}.to have_enqueued_job(PublishContentJob)
      end
    end

    context 'with invalid attributes' do
      before do
        @event_attrs.delete :title
      end

      it 'should respond with errors' do
        subject
        expect(JSON.parse(response.body).has_key?('errors')).to be_truthy
      end

      it 'should respond with 422' do
        subject
        expect(response.code).to eq '422'
      end
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
      expect(BusinessLocation.count).to eq(2)
      expect(assigns(:event).venue).not_to eq(@venue)
      expect(assigns(:event).venue.name).to eq(with_venue_attrs[:venue][:name])
    end

    context 'with listserv_id' do
      before do
        @listserv = FactoryGirl.create :vc_listserv,
            locations: [FactoryGirl.create(:location)]
        @event_attrs[:listserv_ids] = @listserv.id
      end

      it 'adds the listserv locations to the content record' do
        subject
        event_content = assigns(:event).content
        expect(event_content.location_ids.count).to be > 0
        expect(event_content.location_ids).to include(*@listserv.location_ids)
      end
    end

    context "when event category does not exist" do
      before do
        @event_attrs[:category] = '[object Object]'
      end

      it "created event" do
        expect{ subject }.to change{ Event.count }.by(1)
      end
    end

    context "when wants_to_advertise is flagged" do
      subject { post :create, format: :json, event: @event_attrs.merge(wants_to_advertise: true), current_user_id: @current_user.id }

      it "sends email to user with rates" do
        mail = double()
        expect(mail).to receive(:deliver_later)
        expect(AdMailer).to receive(:event_advertising_user_contact).and_return(mail)
        subject
      end

      it "sends email to admin" do
        mail = double()
        expect(mail).to receive(:deliver_later)
        expect(AdMailer).to receive(:event_adveritising_request).with(@current_user, instance_of(Event)).and_return(mail)
        subject
      end
    end

    context 'with promotion location information' do
      let(:radius) { 20 }
      let(:location) { FactoryGirl.create(:location) }
      before do
        @event_attrs[:promote_radius] = radius
        @event_attrs[:ugc_base_location_id] = location.slug
      end

      it 'runs content through UpdateContentLocations process' do
        expect(UpdateContentLocations).to receive(:call).with(instance_of(Content), promote_radius: radius, base_locations: [location])

        subject
      end
    end
  end
end
