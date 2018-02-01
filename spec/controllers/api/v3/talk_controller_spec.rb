require 'spec_helper'

describe Api::V3::TalkController, :type => :controller do
  before do
    @talk_cat = FactoryGirl.create :content_category, name: 'talk_of_the_town'
    @other_location = FactoryGirl.create :location, city: 'Another City'
    @user = FactoryGirl.create :user, location: @other_location
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
      content = FactoryGirl.create :content, :talk,
        title: "Original Title",
        raw_content: "Original Raw Content",
        promote_radius: 50
      @talk = content.channel
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

      context "when non-image params for update" do
        let(:new_title) { "Han's Journey: A Memoir" }
        let(:new_content) { "We begin in Tatooine..." }
        let(:new_promote_radius) { 20 }

        let(:talk_params) {
          {
            title: new_title,
            content: new_content,
            promote_radius: new_promote_radius
          }
        }


        subject { put :update, id: @talk.content.id, talk: talk_params }

        it "updates record" do
          expect{ subject }.to change{
            @talk.content.reload.title
          }.to(new_title).and change{
            @talk.content.raw_content
          }.to(new_content).and change{
            @talk.content.promote_radius
          }.to new_promote_radius
        end
      end
    end
  end


  describe 'POST create' do
    before do
      @basic_attrs = {
        title: 'Some Title Here',
        content: 'Hello this is the body',
        promote_radius: 10,
        ugc_base_location_id: FactoryGirl.create(:location).slug
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

      context 'with promotion location information' do
        let(:radius) { 20 }
        let(:location) { FactoryGirl.create(:location) }
        before do
          @basic_attrs[:promote_radius] = radius
          @basic_attrs[:ugc_base_location_id] = location.slug
        end

        it 'runs content through UpdateContentLocations process' do
          expect(UpdateContentLocations).to receive(:call).with(instance_of(Content), promote_radius: radius, base_locations: [location])

          subject
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
