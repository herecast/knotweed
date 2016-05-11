require 'spec_helper'

describe BusinessProfilesController, :type => :controller do
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
      expect(response).to be_success
    end

    it 'loads the business_profiles' do
      subject
      expect(assigns(:business_profiles)).to match_array(BusinessProfile.all)
    end

    context 'with search params' do
      it 'should respond with matching business_profiles' do
        get :index, q: { business_location_name_cont: @business_profiles.first.business_location.name }
        expect(assigns(:business_profiles)).to eq [@business_profiles.first]
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
      @bl = @bp.business_location
      @attrs_for_update = {
        business_location_attributes: {
          name: 'New, Different Name',
          venue_url: 'http://www.new-website-123.com',
          id: @bl.id,
          address: Faker::Address.street_address,
          city: Faker::Address.city,
          state: Faker::Address.state
        }
      }
    end

    subject { put :update, id: @bp.id, business_profile: @attrs_for_update, continue_editing: true }

    it 'should update business_location attributes' do
      expect{subject}.to change{@bl.reload.address}.to @attrs_for_update[:business_location_attributes][:address]
    end

    context "when update fails" do
      before do
        allow_any_instance_of(BusinessProfile).to receive(:update_attributes!).and_return false
      end

      it "renders edit page" do
        subject
        expect(response).to render_template 'edit'
      end
    end
  end

  describe "POST 'create'" do
    before do
      @attrs_for_create = {
        business_location_attributes: {
          name: Faker::Company.name,
          address: Faker::Address.street_address,
          city: Faker::Address.city,
          state: Faker::Address.state
        }
      }
    end

    subject { post :create, business_profile: @attrs_for_create }

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

      subject { post :create, business_profile: { business_location_attributes: { name: Faker::Company.name } } }

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
      expect(response).to be_success
    end
  end
end
