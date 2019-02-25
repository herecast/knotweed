require 'spec_helper'

RSpec.describe 'Organzation Hides Endpoints', type: :request do
  let(:organization) { FactoryGirl.create :organization }
  let(:user) { FactoryGirl.create :user }
  let(:headers) { auth_headers_for(user) }
  let(:params) { { organization_hide: { flag_type: 'Spammy' } } }

  describe 'POST /api/v3/organizations/:organization_id/hides' do
    subject do
      post "/api/v3/organizations/#{organization.id}/hides",
        headers: headers,
        params: params
    end

    it "creates OrganizationHide" do
      expect{ subject }.to change{
        OrganizationHide.count
      }.by 1
    end

    context "when OrganizationHide exists but deleted_at is not null" do
      before do
        @org_hide = FactoryGirl.create :organization_hide,
          organization_id: organization.id,
          user_id: user.id,
          deleted_at: Date.yesterday
      end

      it "does not create new OrganizationHide" do
        expect{ subject }.not_to change{
          OrganizationHide.count
        }
      end

      it "updates deleted_at to nil" do
        expect{ subject }.to change{
          @org_hide.reload.deleted_at
        }.to nil
      end
    end
  end

  describe 'DELETE /api/v3/organizations/hides/:id' do
    before do
      @org_hide = FactoryGirl.create :organization_hide,
        organization_id: organization.id,
        user_id: user.id,
        deleted_at: nil
    end

    subject do
      delete "/api/v3/organizations/hides/#{@org_hide.id}",
        headers: headers
    end

    it "updates deleted_at to current time" do
      expect{ subject }.to change{
        @org_hide.reload.deleted_at
      }
    end
  end
end