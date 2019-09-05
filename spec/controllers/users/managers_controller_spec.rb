# frozen_string_literal: true

require 'spec_helper'

describe Users::ManagersController, type: :controller do
  let(:user) { FactoryGirl.create :admin }

  before { sign_in user }

  describe 'for organizations' do
    let!(:organization) { FactoryGirl.create :organization }

    describe 'POST #create' do
      subject { post :create, params: { organization_id: organization.id, user_id: user.id } }

      it 'adds user to organization as manager' do
        subject
        expect(user.has_role?(:manager, organization)).to be true
      end
    end

    describe 'DELETE #destroy' do
      before { user.add_role :manager, organization }

      subject { delete :destroy,
        params: { organization_id: organization.id,
          id: organization.id,
          user_id: user.id } }

      it 'removes user as organization manager' do
        expect { subject }.to change { user.roles.count }.by -1
      end
    end
  end
end
