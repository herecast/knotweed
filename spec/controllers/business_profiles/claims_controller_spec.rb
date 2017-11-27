require 'spec_helper'

describe BusinessProfiles::ClaimsController, type: :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
    @business_profile = FactoryGirl.create :business_profile
  end

  describe "POST #create" do

    subject { post :create, id: @business_profile }

    context "when successful" do
      it "makes call to business profile structure service" do
        expect(CreateBusinessProfileRelationship).to receive(:call)
        subject
      end

      it "creates structure for claimed business" do
        subject
        @business_profile.reload
        expect(@business_profile.content.channel_type).to eq 'BusinessProfile'
        expect(@business_profile.content.organization.org_type).to be_truthy
        expect(@business_profile.claimed?).to be true
      end
    end

    context "when not successful" do
      it "returns flash warning" do
        allow(BusinessProfile).to receive(:find_by).and_return(nil)
        subject
        @business_profile.reload
        expect(@business_profile.claimed?).to be false
        expect(flash.now[:warning]).to be_truthy
      end
    end
  end

end