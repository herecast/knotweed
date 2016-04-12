require 'spec_helper'

describe Api::V3::OrganizationsController, :type => :controller do
  describe 'GET index' do
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
      index
    end

    subject { get :index }

    it 'has 200 status code' do
      subject
      expect(response.code).to eq('200')
    end

    it 'only responds with organizations associated with news content' do
      subject
      expect(assigns(:organizations).include?(@organization)).to eq true
      expect(assigns(:organizations).include?(@non_news_org)).to eq false
      expect(assigns(:organizations).include?(@difft_app_org)).to eq true
    end

    it 'filters by consumer app if requesting app is available' do
      get :index, format: :json, consumer_app_uri: @consumer_app.uri
      expect(assigns(:organizations)).to eql([@organization])
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

    context 'not signed in' do
      it 'should respond with 403' do
        subject
        expect(response.code).to eq '403'
      end
    end

    context 'signed in but not authorized' do
      before do
        @user = FactoryGirl.create :user
        api_authenticate user: @user
      end

      it 'should respond with 403' do
        subject
        expect(response.code).to eq '403'
      end
    end

    context 'as authorized user' do
      before do
        @user = FactoryGirl.create :user
        @user.add_role :manager, @org1
        api_authenticate user: @user
      end

      context 'with consumer app specified' do
        before do
          @consumer_app = FactoryGirl.create :consumer_app
          api_authenticate user: @user, consumer_app: @consumer_app
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
  end
end
