require 'spec_helper'

describe BusinessProfiles::ArchivingsController, type: :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
    @business_profile = FactoryGirl.create :business_profile
  end

  describe 'POST #create' do

    subject { post :create, id: @business_profile.id, business_profile: { archived: true } }

    context "when successful" do
      it "flags business profile as archived" do
        subject
        @business_profile.reload
        expect(@business_profile.archived).to be true
        expect(flash.now[:notice]).to be_truthy
      end
    end

    context "when not successful" do
      it "returns warning flash" do
        allow_any_instance_of(BusinessProfile).to receive(:update_attributes).and_return(false)
        subject
        @business_profile.reload
        expect(@business_profile.archived).to be false
        expect(flash.now[:warning]).to be_truthy
      end
    end
  end

  describe 'DELETE :destroy' do
    before do
      @business_profile.update_attribute(:archived, true)
    end

    subject { delete :destroy, id: @business_profile.id, business_profile: { archived: false } }

    context "when successful" do
      it "flags bussiness profile as not archived" do
        subject
        @business_profile.reload
        expect(@business_profile.archived).to be false
        expect(flash.now[:notice]).to be_truthy
      end
    end

    context "when not successful" do
      it "returns warning flash" do
        allow_any_instance_of(BusinessProfile).to receive(:update_attributes).and_return(false)
        subject
        @business_profile.reload
        expect(@business_profile.archived).to be true
        expect(flash.now[:warning]).to be_truthy
      end
    end
  end

end