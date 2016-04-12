require 'spec_helper'

describe BusinessProfilesController do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  describe "GET 'index'" do
    before do
      @business_profiles = FactoryGirl.create_list :business_profile, 5
    end

    subject { get :index, q: { id_in: [] } }

    it "returns http success" do
      subject
      response.should be_success
    end

    it 'loads the business_profiles' do
      subject
      assigns(:business_profiles).should eq(@business_profiles)
    end

    context 'with search params' do
      it 'should respond with matching business_profiles' do
        get :index, q: { content_title_cont: @business_profiles.first.content.title }
        assigns(:business_profiles).should eq [@business_profiles.first]
      end
    end

    context "when reset" do

      subject { get :index, reset: true }

      it "responds with no business profiles" do
        subject
        expect(assigns(:business_profiles)).to eq []
      end
    end
  end

  describe "PUT 'update'" do
    before do
      @bp = FactoryGirl.create :business_profile
      @content = @bp.content
      @org = @content.organization
      @bl = @bp.business_location
      @attrs_for_update = {
        content_attributes: {
          id: @content.id,
          organization_attributes: {
            id: @org.id,
            website: 'http://www.new-website-123.com'
          },
          title: 'New, Different Title'
        },
        business_location_attributes: {
          id: @bl.id,
          address: Faker::Address.street_address,
          city: Faker::Address.city,
          state: Faker::Address.state
        }
      }
    end

    subject { put :update, id: @bp.id, business_profile: @attrs_for_update, continue_editing: true }

    it 'should update organization website' do
      expect{subject}.to change{@org.reload.website}.to @attrs_for_update[:content_attributes][:organization_attributes][:website]
    end

    it 'should update organization name' do
      expect{subject}.to change{@org.reload.name}.to @attrs_for_update[:content_attributes][:title]
    end

    it 'should update business_location attributes' do
      expect{subject}.to change{@bl.reload.address}.to @attrs_for_update[:business_location_attributes][:address]
    end

    it 'should update content attributes' do
      expect{subject}.to change{@content.reload.title}.to @attrs_for_update[:content_attributes][:title]
    end

    context "when update fails" do
      before do
        allow_any_instance_of(BusinessProfile).to receive(:update_attributes!).and_return false
      end

      subject { put :update, id: @bp.id, business_profile: { content_attributes: { title: 'title', organization_attributes: {} } } }

      it "renders edit page" do
        subject
        expect(response).to render_template 'edit'
      end
    end
  end

  describe "POST 'create'" do
    before do
      @attrs_for_create = {
        content_attributes: {
          organization_attributes: {
            website: Faker::Internet.url
          },
          title: Faker::Company.name
        },
        business_location_attributes: {
          address: Faker::Address.street_address,
          city: Faker::Address.city,
          state: Faker::Address.state
        }
      }
    end

    subject { post :create, business_profile: @attrs_for_create }

    it 'should create an organization record' do
      expect{subject}.to change{Organization.count}.by 1
    end

    it 'should create a content record' do
      expect{subject}.to change{Content.count}.by 1
    end

    it 'should create a business_location record' do
      expect{subject}.to change{BusinessLocation.count}.by 1
    end

    it 'should create a business_profile record' do
      expect{subject}.to change{BusinessProfile.count}.by 1
    end

    context "when create fails" do
      before do
        allow_any_instance_of(BusinessProfile).to receive(:save).and_return false
      end

      subject { post :create, business_profile: { content_attributes: { title: 'title', organization_attributes: {} } } }

      it "renders new page" do
        subject
        expect(response).to render_template 'new'
      end
    end
  end

  describe 'GET #new' do

    subject { get :new }

    it "responds with 200 status code" do
      subject
      expect(response.code).to eq '200'
    end
  end

  describe "GET 'edit'" do
    before do
      @bp = FactoryGirl.create :business_profile
    end

    subject { get :edit, id: @bp.id }

    it "returns http success" do
      subject
      response.should be_success
    end
  end
end
