# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Api::V3::Users::PaymentsController, type: :controller do
  describe 'GET #index' do
    let(:user) { FactoryGirl.create :user }
    subject { get :index, params: { user_id: user.id } }

    context 'when no user logged in' do
      it 'should return unauthorized status' do
        subject
        expect(response).to have_http_status :unauthorized
      end
    end

    context 'with logged in user who IS manager' do
      before { api_authenticate user: user }

      it 'should respond with 200' do
        subject
        expect(response).to have_http_status :success
      end

      describe 'returns' do
        let(:contents) { FactoryGirl.create_list :content, 15, created_by: user }
        before do
          15.times do |i|
            FactoryGirl.create :payment, content: contents[i],
                                         payment_date: i.days.ago, paid_to: user,
                                         period_start: 1.month.ago, period_end: Date.today,
                                         paid: true
          end
        end

        it 'one aggregated payment' do
          subject
          expect(assigns(:payments).length).to eq 1
        end
      end

      describe 'excludes' do
        let!(:payment) { FactoryGirl.create :payment, paid_to: user, paid: false }

        it 'unpaid payments' do
          subject
          expect(assigns(:payments)).to eq []
        end
      end
    end
  end
end
