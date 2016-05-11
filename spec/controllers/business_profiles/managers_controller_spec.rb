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

    subject { post :create, business_profile_id: @business_profile.id, user_id: @user.id }

    it "adds user to business profile as manager" do
      subject
      @user.reload
      expect(@user.roles.last.resource_type).to eq 'Organization'
      expect(@user.roles.last.resource_id).to eq @organization.id
    end
  end

  describe "DELETE #destroy" do

    subject { delete :destroy, id: @business_profile.id, user_id: @user.id }

    it "removes user as business profile manager" do
      @user.add_role :manager, @organization
      expect{ subject }.to change{ @user.roles.count }.by -1
    end
  end
end