require 'rails_helper'

RSpec.describe SendPaymentsJob do
  let(:period_start) { 2.weeks.ago }
  let(:period_end) { Date.today }

  subject { described_class.new.perform(period_start.to_s, period_end.to_s) }

  describe 'with unpaid payments' do
    let!(:payment) {
      FactoryGirl.create :payment, period_start: period_start, period_end: period_end,
                                   paid: false
    }
    let(:send_payment_params) {
      {
        vendor_name: payment.paid_to.fullname,
        amount: payment.total_payment,
        invoice_number: payment.id,
        invoice_date: payment.invoice_date
      }
    }

    describe 'when the BillDotCom call succeeds' do
      before { allow(BillDotComService).to receive(:send_payment).with(send_payment_params).and_return(true) }

      it 'should update the payment as paid' do
        expect { subject }.to change { payment.reload.paid }.to true
      end
    end

    describe 'when the BillDotCom call fails' do
      before {
        allow(BillDotComService).to receive(:send_payment).with(send_payment_params)
                                                          .and_raise(BillDotComExceptions::UnexpectedResponse.new("Generic problem error"))
      }

      it 'should not update the payment as paid' do
        subject
        expect(payment.reload.paid).to be false
      end
    end
  end
end
