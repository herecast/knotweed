# frozen_string_literal: true

require 'spec_helper'

describe Organizations::UsersController, type: :controller do
  let(:admin) { FactoryGirl.create :admin }
  before { sign_in admin }

  describe 'GET #index' do
    let(:organization) { FactoryGirl.create :organization }
    subject! { get :index, params: { organization_id: organization.id } }

    it 'should respond with 200' do
      expect(response).to have_http_status :ok
    end

    it 'should load the organization' do
      expect(assigns(:organization)).to eq organization
    end
  end
end
