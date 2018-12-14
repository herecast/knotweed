require 'spec_helper'

RSpec.describe CreateBusinessProfileRelationship do
  describe "::call" do
    before do
      @business_profile = FactoryGirl.create :business_profile
      @org_name = "New Order Swag"
    end

    context "when BusinessProfile does not exist" do
      before do
        @org_name = "Hoth Merch"
      end

      subject { CreateBusinessProfileRelationship.call(org_name: @org_name) }

      it "creates new BusinessProfile and BusinessLocation" do
        expect { subject }.to change {
          BusinessProfile.count
        }.by(1).and change {
          BusinessLocation.count
        }.by 1
      end
    end

    let(:opts) { { org_name: @org_name, business_profile: @business_profile } }

    subject { CreateBusinessProfileRelationship.call(opts) }

    context "when BusinessProfile Content record already exists" do
      before do
        @content = FactoryGirl.create :content,
                                      channel_id: @business_profile.id,
                                      channel_type: 'BusinessProfile'
      end

      it "updates content record accordingly" do
        subject
        @content.reload
        expect(@content.title).to eq @content.organization.name
        expect(@content.pubdate).not_to be_nil
      end
    end

    context "when BusinessProfile name matches an Organization" do
      before do
        @organization = FactoryGirl.create :organization, name: @org_name
      end

      it "creates Content record accordingly" do
        subject
        @business_profile.reload
        expect(@business_profile.content.title).to eq @org_name
        expect(@business_profile.content.pubdate).not_to be_nil
        expect(@business_profile.content.organization_id).to eq @organization.id
      end
    end

    context "when no Content record or matching Organization present" do
      it "creates appropriate Content record and Organization" do
        expect { subject }.to change {
          Content.count
        }.by(1).and change {
          Organization.count
        }.by(1)

        @business_profile.reload
        expect(@business_profile.content.title).to eq @org_name
        expect(@business_profile.content.pubdate).not_to be_nil
      end
    end
  end
end
