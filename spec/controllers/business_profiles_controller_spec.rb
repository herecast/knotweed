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

    subject { get :index, params: { q: { id_in: "" } } }

    it "returns http success" do
      subject
      expect(response).to be_successful
    end

    it 'loads the business_profiles' do
      subject
      expect(assigns(:business_profiles)).to match_array(BusinessProfile.all)
    end

    context 'with search params' do
      it 'should respond with matching business_profiles' do
        get :index, params: { q: { business_location_name_cont: @business_profiles.first.business_location.name } }
        expect(assigns(:business_profiles)).to eq [@business_profiles.first]
      end
    end

    context 'when searching by category' do
      let(:business_category) { FactoryGirl.create :business_category }

      subject { get :index, params: { q: { business_categories_id_in: [business_category.id] } } }

      it 'returns matching businesses' do
        @business_profiles[0].business_categories << business_category
        subject
        expect(assigns(:business_profiles)).to match_array [@business_profiles[0]]
      end
    end

    context "when searching for businesses by claim" do
      before do
        @business_profiles[0].content = FactoryGirl.create :content
        organization = FactoryGirl.create :organization, org_type: 'Business'
        @business_profiles[0].content.update_attribute(:organization_id, organization.id)
      end

      context "when selecting claimed businesses" do
        subject { get :index, params: { q: { content_organization_org_type_present: true } } }

        it "returns claimed business profiles" do
          subject
          expect(assigns(:business_profiles)).to match_array [@business_profiles[0]]
        end
      end

      context "when selecting unclaimed businesses" do
        subject { get :index, params: { q: { content_organization_org_type_present: false } } }

        it "returns unclaimed business_profiles" do
          subject
          expect(assigns(:business_profiles)).not_to include @business_profiles[0]
        end
      end
    end

    context "when searching by archiving status" do
      context "when querying for active" do
        subject { get :index, params: { q: { archived_eq: false } } }

        it "returns unarchived business profiles" do
          @business_profiles[1..4].map { |bp| bp.update_attribute(:archived, true) }
          subject
          expect(assigns(:business_profiles)).to match_array [@business_profiles[0]]
        end
      end

      context "when querying for archived" do
        subject { get :index, params: { q: { archived_eq: true } } }

        it "returns archived business profiles" do
          @business_profiles[0].update_attribute :archived, true
          subject
          expect(assigns(:business_profiles)).to match_array [@business_profiles[0]]
        end
      end
    end

    context "when reset" do
      subject { get :index, params: { reset: true } }

      it "responds with no business profiles" do
        subject
        expect(assigns(:business_profiles)).to eq []
      end
    end
  end

  describe "PUT 'update'" do
    before do
      @bp = FactoryGirl.create :business_profile, :claimed
      @bp.content.organization.update_attribute(:org_type, 'Business')
      @bl = @bp.business_location
      @attrs_for_update = {
        business_location_attributes: {
          name: 'New, Different Name',
          venue_url: 'http://www.new-website-123.com',
          id: @bl.id,
          address: Faker::Address.street_address,
          city: Faker::Address.city,
          state: Faker::Address.state_abbr
        }
      }
    end

    context "when update succeeds" do
      subject { put :update, params: { id: @bp.id, business_profile: @attrs_for_update, continue_editing: true } }

      it 'should update business_location attributes' do
        expect { subject }.to change { @bl.reload.address }.to @attrs_for_update[:business_location_attributes][:address]
      end
    end

    context "when update fails" do
      before do
        allow_any_instance_of(BusinessProfile).to receive(:update_attributes).and_return false
      end

      subject { put :update, params: { id: @bp.id, business_profile: @attrs_for_update, continue_editing: true } }

      it "renders edit page" do
        subject
        expect(response).to render_template 'edit'
      end
    end

    context "when removing image from claimed business profile" do
      before do
        @image = FactoryGirl.create(:image)
        @image.image = File.open(File.join(Rails.root, '/spec/fixtures/photo.jpg'))
        @bp.content.images << @image
      end

      subject {
        put :update, params: {
          id: @bp.id,
          create_new: true,
          business_profile: {
            content_attributes: {
              id: @bp.content.id,
              images_attributes: {
                '0' => {
                  id: @image.id,
                  remove_image: '1'
                }
              }
            }
          }
        }
      }

      it "deletes image selected for deletion" do
        subject
        @bp.reload
        expect(@bp.content.primary_image.image.url).to be_nil
      end
    end

    context "when removing logo from claimed business profile organization" do
      before do
        @bp.content.organization.logo = File.open(File.join(Rails.root, '/spec/fixtures/photo.jpg'))
      end

      subject { put :update, params: { id: @bp.id, business_profile: { content_attributes: { id: @bp.content.id, organization_attributes: { id: @bp.content.organization.id, remove_logo: '1' } } } } }

      it "deletes :logo" do
        subject
        @bp.reload
        expect(@bp.content.organization.logo.url).to be_nil
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
          state: Faker::Address.state_abbr
        },
        content_attributes: {
          channel_type: 'BusinessProfile'
        }
      }
    end

    subject { post :create, params: { business_profile: @attrs_for_create } }

    it 'should create a business_location record' do
      expect { subject }.to change { BusinessLocation.count }.by 1
    end

    it 'should create a business_profile record' do
      expect { subject }.to change { BusinessProfile.count }.by 1
    end

    it 'should create a claimed business' do
      subject
      expect(BusinessProfile.last.claimed?).to be true
    end

    it 'makes call to create business profile relationship' do
      expect(CreateBusinessProfileRelationship).to receive(:call)
      subject
    end

    context "when create fails" do
      before do
        allow_any_instance_of(BusinessProfile).to receive(:save).and_return false
      end

      subject { post :create, params: { business_profile: { business_location_attributes: { name: Faker::Company.name } } } }

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

    context "when business not claimed" do
      subject { get :edit, params: { id: @bp.id } }

      it "redirects to index" do
        subject
        expect(response).to redirect_to business_profiles_path
      end
    end

    context "when business_profile is claimed" do
      before do
        @bp.content = FactoryGirl.create :content
        organization = FactoryGirl.create :organization, org_type: 'Business'
        @bp.content.update_attribute(:organization_id, organization.id)
      end

      subject { get :edit, params: { id: @bp.id } }

      context "when business profile has no managers" do
        it "returns http success" do
          expect(response).to have_http_status 200
        end
      end

      context "when business profile has managers" do
        before do
          @manager = FactoryGirl.create :user, email: 'bill@deblasio.com'
          @manager.add_role :manager, @bp.content.organization
        end

        it "assigns managers" do
          subject
          expect(assigns(:managers)).to match_array [@manager]
        end
      end
    end
  end
end
