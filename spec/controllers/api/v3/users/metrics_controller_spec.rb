# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Api::V3::Users::MetricsController, type: :controller do
  describe 'GET #index' do
    let(:start_date) { 1.week.ago }
    let(:end_date) { 1.week.from_now }
    let(:user) { FactoryGirl.create :user }

    subject { get :index, params: { user_id: user.id, start_date: start_date, end_date: end_date } }

    context 'when no user logged in' do
      it 'should return unauthorized status' do
        subject
        expect(response).to have_http_status :unauthorized
      end
    end

    context 'with logged in user who IS manager' do
      let(:user) { FactoryGirl.create :user }
      before { api_authenticate user: user }

      it 'should respond with 200' do
        subject
        expect(response).to have_http_status :success
      end

      context 'with missing request params' do
        subject { get :index, params: { user_id: user.id } }
        it 'should respond with bad_request' do
          subject
          expect(response).to have_http_status :bad_request
        end
      end
    end
  end
end
