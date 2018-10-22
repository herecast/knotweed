require 'spec_helper'

RSpec.describe Api::V3::Organizations::MetricsController, type: :controller do
  describe 'GET #index' do
    let(:start_date) { 1.week.ago }
    let(:end_date) { 1.week.from_now }
    let(:org) { FactoryGirl.create :organization }
    subject { get :index, params: { organization_id: org.id, start_date: start_date, end_date: end_date } }

    context "when no user logged in" do
      it "should return unauthorized status" do
        subject
        expect(response).to have_http_status :forbidden
      end
    end

    context 'with logged in user who is NOT a manager' do
      let(:user) { FactoryGirl.create :user }
      before { api_authenticate user: user }

      it 'should return unuathorized status' do
        subject
        expect(response).to have_http_status :forbidden
      end
    end

    context 'with logged in user who IS manager' do
      let(:user) { FactoryGirl.create :user }
      before do
        user.add_role :manager, org
        api_authenticate user: user
      end

      it 'should correctly assign the organization instance variable' do
        subject
        expect(assigns(:organization)).to eq org
      end

      it 'should respond with 200' do
        subject
        expect(response).to have_http_status :success
      end
    end
  end
end
