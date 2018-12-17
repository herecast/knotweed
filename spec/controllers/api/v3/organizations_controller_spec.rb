require 'spec_helper'
require 'sidekiq/testing'

describe Api::V3::OrganizationsController, :type => :controller do
  describe 'GET index', elasticsearch: true do
    before do
      @organization = FactoryGirl.create :organization
      @non_news_org = FactoryGirl.create :organization
      @difft_app_org = FactoryGirl.create :organization
      @news_cat = FactoryGirl.create :content_category, name: 'news'
      FactoryGirl.create(:content, organization: @organization,
                                   content_category: @news_cat)
      FactoryGirl.create(:content, organization: @difft_app_org,
                                   content_category: @news_cat)
      Organization.reindex
    end

    subject { get :index }

    it 'has 200 status code' do
      subject
      expect(response.code).to eq('200')
    end

    it 'only responds with organizations associated with news content' do
      subject
      expect(assigns(:organizations)).to match_array([@organization, @difft_app_org])
    end

    describe 'with a list of organization ids' do
      before do
        @list_of_orgs = FactoryGirl.create_list :organization, 3
      end

      subject { get :index, params: { ids: @list_of_orgs.map { |o| o.id } } }

      it 'should respond with 200' do
        subject
        expect(response.code).to eq '200'
      end

      it 'should respond with the specified organizations' do
        subject
        expect(assigns(:organizations)).to match_array @list_of_orgs
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

    subject { post :create, params: params }

    it "creates Organization" do
      expect { subject }.to change {
        Organization.count
      }.by 1
    end

    it "provisions Org as blog" do
      subject
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
      expect { subject }.to change {
        BusinessLocation.count
      }.by 1
    end

    it "calls to schedules Blogger outreach emails" do
      expect(BackgroundJob).to receive(:perform_later).with(
        'Outreach::CreateMailchimpSegmentForNewUser',
        'call',
        @user,
        schedule_blogger_emails: true,
        organization: an_instance_of(Organization)
      )
      subject
    end

    context "when PRODUCTION_MESSAGING_ENABLED" do
      before do
        allow(Figaro.env).to receive(:production_messaging_enabled).and_return('true')
      end

      it 'sends notification to Slack' do
        subject
        queue = ActiveJob::Base.queue_adapter.enqueued_jobs
        expect(queue.select { |j| j[:args][0] == 'SlackService' }.length).to eq 1
      end
    end
  end

  describe 'PUT update' do
    before do
      @org = FactoryGirl.create :organization
    end

    let(:put_params) do
      {
        format: :json,
        params: {
          id: @org.id,
          organization: {
            name: 'New Name',
            description: Faker::Lorem.sentence(2),
            logo: fixture_file_upload('/photo.jpg', 'image/jpg')
          }
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
        expect { subject }.to change { @org.reload.description }
      end

      it 'should update name' do
        expect { subject }.to change { @org.reload.name }
      end

      context "when BusinessLocation params are present" do
        before do
          @business_location = FactoryGirl.create :business_location, venue_url: 'https://old.venue'
          @org.business_locations << @business_location
          @new_venue_url = 'https://new.venue'
        end

        let(:new_put_params) do
          {
            format: :json,
            params: {
              id: @org.id,
              organization: {
                website: @new_venue_url
              }
            }
          }
        end

        subject { put :update, new_put_params }

        it "updates BusinessLocation" do
          expect { subject }.to change {
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
        expect { subject }.to_not change { @org.reload.name }
      end
    end
  end
end
