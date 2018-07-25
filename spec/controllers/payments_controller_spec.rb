require 'rails_helper'

RSpec.describe PaymentsController, type: :controller do
  let(:admin) { FactoryGirl.create :admin }
  before { sign_in admin }


  describe "GET #index" do
    subject { get :index }

    it "returns http success" do
      subject
      expect(response).to have_http_status(:success)
    end

    describe 'paid payments' do
      let!(:payment) { FactoryGirl.create :payment, paid: true }

      it 'should not be included' do
        subject
        expect(assigns(:payment_data)).to eql({})
      end
    end

    describe 'with unpaid payments in a period' do
      let(:period_start) { 1.week.ago }
      let(:period_end) { Date.today }
      let!(:promotion_metrics) { FactoryGirl.create_list :promotion_banner_metric, payment.paid_impressions,
        content: payment.content, created_at: (period_start + 1.day) }
      let!(:payment) { FactoryGirl.create :payment, period_start: period_start, period_end: period_end, paid: false }

      it 'should correctly construct the `payment_data` instance variable' do
        subject
        expect(assigns(:payment_data)).to eql({
          "#{period_start.strftime("%m/%d/%Y")} - #{period_end.strftime("%m/%d/%Y")}" => {
            total_impressions: payment.paid_impressions,
            total_payments: payment.total_payment,
            users: {
              payment.paid_to.fullname => {
                id: payment.paid_to.id,
                total_impressions: payment.paid_impressions,
                total_payment: payment.total_payment,
                organizations: {
                  payment.content.organization.name => {
                    id: payment.content.organization.id,
                    payments: [payment]
                  }
                }
              }
            }
          }
        })
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:period_start) { 1.week.ago }
    let(:period_end) { Date.today }

    subject { delete :destroy, period_start: period_start.strftime("%m/%d/%Y"), period_end: period_end.strftime("%m/%d/%Y") }

    it "redirects to index" do
      expect(subject).to redirect_to(payments_path)
    end

    context 'with unpaid payments in the requested period' do
      let!(:unpaid_payments) { FactoryGirl.create_list :payment, 3, period_start: period_start, period_end: period_end, paid: false }
      let!(:paid_payment) { FactoryGirl.create :payment, period_start: period_start, period_end: period_end, paid: true }

      it 'destroys the unpaid payments' do
        expect{subject}.to change{ Payment.count }.by(-unpaid_payments.length)
      end

      it 'does not destroy paid payments' do
        subject
        expect(Payment.find(paid_payment.id)).to eq paid_payment
      end
    end
  end

end
