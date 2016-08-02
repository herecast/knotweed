require 'spec_helper'

describe Api::V3::TalkController, :type => :controller do
  before do
    @talk_cat = FactoryGirl.create :content_category, name: 'talk_of_the_town'
    @other_location = FactoryGirl.create :location, city: 'Another City'
    @user = FactoryGirl.create :user, location: @other_location
  end

  describe 'GET index' do
    before do
      @default_location = FactoryGirl.create :location, city: Location::DEFAULT_LOCATION
      @third_location = FactoryGirl.create :location, city: 'Different Again'
      FactoryGirl.create_list :content, 3, content_category: @talk_cat,
        locations: [@default_location], published: true
      FactoryGirl.create_list :content, 5, content_category: @talk_cat,
        locations: [@other_location], published: true
      FactoryGirl.create_list :content, 4, content_category: @talk_cat,
        locations: [@third_location], published: true
      index
    end

    subject { get :index }

    context 'not signed in' do
      it 'should respond with 401 status' do
        subject
        expect(response.code).to eq('401')
      end
    end

    context 'signed in' do
      before do
        api_authenticate user: @user
      end

      context 'with consumer app provided' do
        before do
          @consumer_app = FactoryGirl.create :consumer_app
          # need to identify a talk item that will show up with the automatic location filter
          @talk_item = @other_location.contents.where(content_category_id: @talk_cat).first
          @org = @talk_item.organization
          @consumer_app.organizations << @org
        end

        subject { get :index, consumer_app_uri: @consumer_app.uri }

        it 'should filter by the app\'s organizations' do
          subject
          expect(assigns(:talk)[:results]).to eq([@talk_item])
        end
      end

      it 'has 200 status code' do
        subject
        expect(response.code).to eq('200')
      end

      it 'should respond with talk items in the user\'s location' do
        subject
        expect(assigns(:talk)[:results].select{|c| c.locations.include? @user.location }.count).to eq(assigns(:talk)[:results].count)
      end
    end
  end

  describe 'GET show' do
    before do
      @talk = FactoryGirl.create :content, content_category: @talk_cat, published: true
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

    it 'should increment view_count' do
      expect{subject}.to change{@talk.reload.view_count}.by 1
    end

    context 'when called with an ID that does not match a talk record' do
      before do
        @content = FactoryGirl.create :content # not talk!
      end

      subject! { get :show, id: @content.id }

      it { expect(response.status).to eq 204 }
    end

    describe 'with repository present' do
      before do
        @repo = FactoryGirl.create :repository
        @consumer_app = FactoryGirl.create :consumer_app, repository: @repo
        @consumer_app.organizations << @talk.organization
        stub_request(:post, /#{@repo.recommendation_endpoint}/)
        api_authenticate user: @user, consumer_app: @consumer_app
      end

      it 'should make a call to record_user_visit' do
        subject
        expect(WebMock).to have_requested(:post, /#{@repo.recommendation_endpoint}/)
      end
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
      @talk = FactoryGirl.create :comment
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
        content: 'Hello this is the body'
      }
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
          @listserv = FactoryGirl.create :listserv
          @basic_attrs[:listserv_id] = @listserv.id
        end

        it { expect{subject}.to change{PromotionListserv.count}.by(1) }
        it { expect{subject}.to change{Promotion.count}.by(1) }
        # triggers mail to both listserv and the user
        it { expect{subject}.to change{ActionMailer::Base.deliveries.count}.by(2) }
      end

      context 'with consumer_app / repository' do
        before do
          @repo = FactoryGirl.create :repository
          @consumer_app = FactoryGirl.create :consumer_app, repository: @repo
          api_authenticate user: @user, consumer_app: @consumer_app
          stub_request(:post, /.*/)
        end

        # because there are so many different external calls and behaviors here,
        # this is really difficult to test thoroughly, but mocking and checking
        # that the external call is made tests the basics of it.
        it 'should call publish_to_dsp' do
          subject
          # note, OntotextController adds basic auth, hence the complex gsub
          expect(WebMock).to have_requested(:post, /#{@repo.annotate_endpoint.gsub(/http:\/\//,
            "http://#{Figaro.env.ontotext_api_username}:#{Figaro.env.ontotext_api_password}@")}/)
        end
      end
    end
  end
end
