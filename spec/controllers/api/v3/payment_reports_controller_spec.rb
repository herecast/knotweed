# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Api::V3::PaymentReportsController, type: :controller do
  describe 'GET #index' do
    let(:period_start) { 1.month.ago }
    let(:period_end) { Date.today }
    let(:user) { FactoryGirl.create :user }

    describe 'with user_id' do
      subject { get :index, params: { user_id: user.id, period_start: period_start, period_end: period_end } }

      context 'when no user logged in' do
        it 'should return unauthorized status' do
          subject
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'as the user in question' do
        before { api_authenticate user: user }

        it 'should respond with 200' do
          subject
          expect(response).to have_http_status :success
        end

        describe 'paid payments' do
          let!(:payment) do
            FactoryGirl.create :payment, period_start: period_start,
                                         period_end: period_end, paid_to: user, paid: false
          end

          it 'should not be included' do
            subject
            expect(assigns(:line_items)).to eq []
          end
        end

        describe 'with payments from multiple organizations' do
          let(:c1) { FactoryGirl.create :content, organization: org1, created_by: user }
          let(:c2) { FactoryGirl.create :content, organization: org1, created_by: user }
          let(:c3) { FactoryGirl.create :content, organization: org2, created_by: user }
          let(:org1) { FactoryGirl.create :organization }
          let(:org2) { FactoryGirl.create :organization }
          let!(:payment1) do
            FactoryGirl.create :payment, period_start: period_start,
                                         period_end: period_end, content: c1, paid_to: user, paid: true
          end
          let!(:payment2) do
            FactoryGirl.create :payment, period_start: period_start,
                                         period_end: period_end, content: c2, paid_to: user, paid: true
          end
          let!(:payment3) do
            FactoryGirl.create :payment, period_start: period_start,
                                         period_end: period_end, content: c3, paid_to: user, paid: true
          end

          it 'should correctly assign total_payment' do
            subject
            expect(assigns(:total_payment)).to eq(payment1.total_payment + payment2.total_payment + payment3.total_payment)
          end

          it 'should correctly assign paid_impressions' do
            subject
            expect(assigns(:paid_impressions)).to eq(payment1.paid_impressions + payment2.paid_impressions + payment3.paid_impressions)
          end

          it 'should aggregate the correct number of organizations for line_items' do
            subject
            expect(assigns(:line_items).length).to eq 2
          end

          it 'should correctly sum the number of reads under organizations for line_items' do
            subject
            result = assigns(:line_items)
            expect(result.map(&:total_impressions)).to match_array([(payment1.paid_impressions + payment2.paid_impressions), payment3.paid_impressions])
          end
        end
      end
    end
  end
end
