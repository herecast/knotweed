require 'spec_helper'

describe Organizations::UsersController, type: :controller do
  describe 'GET #index' do
    let(:organization) { FactoryGirl.create :organization }
    subject { get :index, id: organization.id }

    it 'should respond with 200' do
      expect(response).to have_http_status :ok
    end
  end
end
