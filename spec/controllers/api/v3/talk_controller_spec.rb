require 'spec_helper'

describe Api::V3::TalkController, :type => :controller do
  before do
    @talk_cat = FactoryGirl.create :content_category, name: 'talk_of_the_town'
    @other_location = FactoryGirl.create :location, city: 'Another City'
    @user = FactoryGirl.create :user, location: @other_location
  end

  describe 'GET index', elasticsearch: true do
    before do
      @default_location = FactoryGirl.create :location,
        id: Location::REGION_LOCATION_ID,
        city: Location::DEFAULT_LOCATION
      @third_location = FactoryGirl.create :location, city: 'Different Again'
      FactoryGirl.create_list :content, 3, :talk,
        locations: [@default_location], published: true
      FactoryGirl.create_list :content, 5, :talk,
        locations: [@other_location], base_locations: [@other_location], published: true
      FactoryGirl.create_list :content, 2, :talk,
        locations: [@other_location], about_locations: [@other_location], published: true
      FactoryGirl.create_list :content, 4, :talk,
        locations: [@third_location], published: true
    end

    subject { get :index }

    context 'with consumer app provided' do
      before do
        @consumer_app = FactoryGirl.create :consumer_app
        # need to identify a talk item that will show up with the automatic location filter
        @talk_item = @default_location.contents.where(content_category_id: @talk_cat).first
        @org = @talk_item.organization
        @consumer_app.organizations << @org
      end

      subject { get :index, consumer_app_uri: @consumer_app.uri }

      it 'should filter by the app\'s organizations' do
        subject
        expect(assigns(:talk)[:results].to_a).to eq([@talk_item])
      end
    end

    it_behaves_like "Location based index" do
      let(:content_type) { :talk }
      let(:content_attrs) {
        {organization: @org}
      }
      let(:assigned_var) { assigns(:talk)[:results] }
    end
  end

  describe 'GET show' do
    before do
      @talk = FactoryGirl.create :content, :talk, content_category: @talk_cat, published: true
      api_authenticate user: @user
    end

    subject { get :show, id: @talk.id, format: :json }

    it 'has 200 status code' do
      subject
      expect(response.code).to eq('200')
    end

    it 'appropriately loads the talk object' do
      subject
      expect(assigns(:talk)).to eq(@talk)
    end

    context 'when called with an ID that does not match a talk record' do
      before do
        @content = FactoryGirl.create :content # not talk!
      end

      subject! { get :show, id: @content.id }

      it { expect(response.status).to eq 204 }
    end

    context 'when requesting app includes the talk\'s organization' do
      before do
        organization = FactoryGirl.create :organization
        @talk.organization = organization
        @talk.save
        @consumer_app = FactoryGirl.create :consumer_app, organizations: [organization]
        api_authenticate user: @user, consumer_app: @consumer_app
      end

      it 'should respond with the talk record' do
        subject
        expect(response.status).to eq 200
        expect(assigns(:talk)).to eq @talk
      end
    end

    context 'when requesting app DOES NOT HAVE matching organizations' do
      before do
        organization = FactoryGirl.create :organization
        @talk.organization = organization
        @talk.save
        @consumer_app = FactoryGirl.create :consumer_app, organizations: []
        api_authenticate user: @user, consumer_app: @consumer_app
        subject
      end
      it { expect(response.status).to eq 204 }
    end
  end

  describe 'PUT update' do
    before do
      @talk = FactoryGirl.create(:content, :talk).channel
    end

    context 'not signed in' do
      it 'should respond with 401' do
        put :update, id: @talk.content.id
        expect(response.code).to eq('401')
      end
    end

    context 'signed in' do
      before do
        api_authenticate user: @user
        @file = fixture_file_upload('/photo.jpg', 'image/jpg')
      end

      subject { put :update, id: @talk.content.id, talk: { image: @file } }

      it 'should respond with 200' do
        subject
        expect(response.code).to eq('200')
      end

      it 'should create a new Image' do
        expect{subject}.to change{Image.count}.by(1)
      end

      it 'should associate a new Image with the Content record' do
        subject
        expect(assigns(:content).reload.images.present?).to eq(true)
      end


    end
  end


  describe 'POST create' do
    before do
      @basic_attrs = {
        title: 'Some Title Here',
        content: 'Hello this is the body',
        content_locations: [{
          location_id: FactoryGirl.create(:location).slug,
          location_type: 'base'
        }]
      }
      allow(BitlyService).to receive(:create_short_link).with(any_args).and_return('http://bit.ly/12345')
    end

    subject { post :create, talk: @basic_attrs }

    context 'not signed in' do
      it 'should respond with 401' do
        subject
        expect(response.code).to eq('401')
      end
    end

    context 'signed in' do
      before do
        api_authenticate user: @user
      end

      it 'should respond with 201' do
        subject
        expect(response.code).to eq('201')
      end

      it 'should create a comment' do
        expect{subject}.to change{Comment.count}.by(1)
      end

      it 'should create an associated content object' do
        expect{subject}.to change{Content.count}.by(1)
        expect(assigns(:talk).content.present?).to be true
      end

      context 'with listserv_id' do
        before do
          @consumer_app = FactoryGirl.create :consumer_app, uri: 'http://test.me'
          request.headers['Consumer-App-Uri'] = @consumer_app.uri

          @listserv = FactoryGirl.create :vc_listserv,
            locations: [FactoryGirl.create(:location)]
          @basic_attrs[:listserv_id] = @listserv.id
          @ip = '1.1.1.1'
          allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return(@ip)
        end

        it 'promotes the content to the listserv' do
          expect(PromoteContentToListservs).to receive(:call).with(
            instance_of(Content),
            @consumer_app,
            @ip,
            @listserv
          )
          subject
        end

        it 'adds the listserv locations to content locations' do
          expect{subject}.to change { Content.count}.by(1)
          expect(assigns(:talk).content.location_ids).to include(*@listserv.location_ids)
        end
      end

      context 'With locations' do
        let(:locations) { FactoryGirl.create_list(:location, 3) }

        before do
          @basic_attrs[:content_locations] = locations.map do |location|
            { location_id: location.slug }
          end
        end

        it 'allows nested content locations to be specified' do
          subject
          expect(response.status).to eql 201
          expect(Content.last.locations.to_a).to include *locations
        end

        context 'base locations' do
          before do
            @basic_attrs[:content_locations].each{|l| l[:location_type] = 'base'}
          end

          it 'allows nested location type to be specified as base' do
            subject
            expect(response.status).to eql 201
            expect(Content.last.base_locations.to_a).to include *locations
          end
        end
      end

      context 'with consumer_app / repository' do
        before do
          @repo = FactoryGirl.create :repository
          @consumer_app = FactoryGirl.create :consumer_app, repository: @repo
          api_authenticate user: @user, consumer_app: @consumer_app
        end

        it 'should queue the content to be published' do
          expect{subject}.to have_enqueued_job(PublishContentJob)
        end
      end
    end
  end
end
