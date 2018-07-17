require 'spec_helper'

describe Api::V3::OrganizationsController, :type => :controller do
  describe 'GET index', elasticsearch: true do
    before do
      @organization = FactoryGirl.create :organization
      @consumer_app = FactoryGirl.create :consumer_app
      @non_news_org = FactoryGirl.create :organization
      @difft_app_org = FactoryGirl.create :organization
      @news_cat = FactoryGirl.create :content_category, name: 'news'
      FactoryGirl.create(:content, organization: @organization,
        content_category: @news_cat)
      FactoryGirl.create(:content, organization: @difft_app_org,
        content_category: @news_cat)
      @consumer_app.organizations += [@organization, @non_news_org]
      Organization.reindex
    end

    subject { get :index }

    it 'has 200 status code' do
      subject
      expect(response.code).to eq('200')
    end

    it 'only responds with organizations associated with news content' do
      subject
      expect(assigns(:organizations)).to match_array([@organization,@difft_app_org])
    end

    it 'filters by consumer app if requesting app is available' do
      get :index, format: :json, consumer_app_uri: @consumer_app.uri
      expect(assigns(:organizations)).to match_array [@organization]
    end

    describe 'with a list of organization ids' do
      before do
        @list_of_orgs = FactoryGirl.create_list :organization, 3
      end

      subject { get :index, ids: @list_of_orgs.map{|o| o.id} }

      it 'should respond with 200' do
        subject
        expect(response.code).to eq '200'
      end

      it 'should respond with the specified organizations' do
        subject
        expect(assigns(:organizations)).to match_array @list_of_orgs
      end

      context 'with consumer app specified' do
        before do
          @consumer_app.organizations += [@list_of_orgs[0], @list_of_orgs[1]]
          api_authenticate consumer_app: @consumer_app
        end

        it 'should limit the response to organizations associated with the consumer app' do
          subject
          expect(assigns(:organizations)).to match_array([@list_of_orgs[0], @list_of_orgs[1]])
        end
      end
    end
  end

  describe 'GET show' do
    before do
      @org1 = FactoryGirl.create :organization
    end
    subject { get :show, id: @org1.id, format: :json }

    context 'with consumer app specified' do
      before do
        @consumer_app = FactoryGirl.create :consumer_app
        request.headers['Consumer-App-Uri'] = @consumer_app.uri
      end


      context 'without org being associated with consumer app' do
        it 'should respond with a 204' do
          subject
          expect(response.code).to eq '204'
        end
      end

      context 'with org associated with consumer app' do
        before do
          @consumer_app.organizations << @org1
        end

        it 'should respond with a 200' do
          subject
          expect(response.code).to eq '200'
        end

        it 'should load the organization' do
          subject
          expect(assigns(:organization)).to eq @org1
        end
      end
    end
  end

  describe "POST create" do
    before do
      @user = FactoryGirl.create :user
      api_authenticate user: @user
      FactoryGirl.create :location, city: 'Hartford', state: 'VT'
    end

    let(:params) do
      {
        organization: {
            name: 'Hoth Apoth',
            description: 'Thy drugs are quick...',
            website: "https://hothapoth.ho",
            email: "snowman@hothapoth.ho"
        }
      }
    end

    subject { post :create, params }

    it "creates Organization" do
      expect{ subject }.to change{
        Organization.count
      }.by 1
    end

    it "provisions Org as blog" do
      subject
      expect(Organization.last.biz_feed_active).to be true
      expect(Organization.last.can_publish_news).to be true
    end

    it "adds Blogger role to User" do
      subject
      expect(@user.has_role?(:blogger)).to be true
    end

    it "adds logged in user as manager" do
      subject
      expect(@user.ability.can?(:manage, Organization.last)).to be true
    end

    it "creates Business Location for Organization" do
      expect{ subject }.to change{
        BusinessLocation.count
      }.by 1
    end
  end

  describe 'PUT update' do
    before do
      @org = FactoryGirl.create :organization
    end

    let(:put_params) do
      {
        id: @org.id,
        format: :json,
        organization: {
          name: 'New Name',
          description: Faker::Lorem.sentence(2),
          logo: fixture_file_upload('/photo.jpg', 'image/jpg')
        }
      }
    end

    subject { put :update, put_params }

    context 'as authorized user' do
      before do
        @user = FactoryGirl.create :user
        @user.add_role :manager, @org
        api_authenticate user: @user
      end

      after(:all) do
        # executing this request "uploads" an image to public/organization/1
        FileUtils.rm_rf(Dir["#{Rails.root}/public/organization"])
      end

      it 'should respond with 204' do
        subject
        expect(response.code).to eq '204'
      end

      it 'should update description' do
        expect{subject}.to change{@org.reload.description}
      end

      it 'should update name' do
        expect{subject}.to change{@org.reload.name}
      end

      context "when BusinessLocation params are present" do
        before do
          @business_location = FactoryGirl.create :business_location, venue_url: 'https://old.venue'
          @org.business_locations << @business_location
          @new_venue_url = 'https://new.venue'
        end

        let(:new_put_params) do
          {
            id: @org.id,
            format: :json,
            organization: {
              website: @new_venue_url
            }
          }
        end

        subject { put :update, new_put_params }

        it "updates BusinessLocation" do
          expect{ subject }.to change{
            @org.reload.business_locations.first.venue_url
          }.to @new_venue_url
        end
      end
    end

    context 'as unauthorized (but logged in) user' do
      before do
        @user = FactoryGirl.create :user
        api_authenticate user: @user
      end

      it 'should respond with 403' do
        subject
        expect(response.code).to eq '403'
      end

      it 'should not update the organization' do
        expect{subject}.to_not change{@org.reload.name}
      end
    end
  end
end
