require 'spec_helper'

describe BusinessProfiles::ManagersController, type: :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
    @business_profile = FactoryGirl.create :business_profile
    content = FactoryGirl.create :content
    @business_profile.content = content
    @organization = FactoryGirl.create :organization, org_type: 'Business'
    @business_profile.content.update_attribute(:organization, @organization)
  end

  describe "POST #create" do
    context "when toggled through business profile interface" do
      subject { post :create, params: { business_profile_id: @business_profile.id, user_id: @user.id } }

      it "adds user to business profile organization as manager" do
        subject
        @user.reload
        expect(@user.has_role?(:manager, @organization)).to be true
      end
    end

    context "when toggled through organization interface" do
      subject { post :create, params: { organization_id: @organization.id, user_id: @user.id } }

      it "adds user to organization as manager" do
        subject
        @user.reload
        expect(@user.has_role?(:manager, @organization)).to be true
      end
    end
  end

  describe "DELETE #destroy" do
    before do
      @user.add_role :manager, @organization
    end

    context "when toggled through business profile interface" do
      subject { delete :destroy, params: { business_profile_id: @business_profile.id, user_id: @user.id } }

      it "removes user as business profile manager" do
        expect { subject }.to change { @user.roles.count }.by -1
      end
    end

    context "when toggled through organization interface" do
      subject { delete :destroy, params: { organization_id: @organization.id, user_id: @user.id } }

      it "removes user as organization manager" do
        expect { subject }.to change { @user.roles.count }.by -1
      end
    end
  end
end
