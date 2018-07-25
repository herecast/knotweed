require 'rails_helper'

RSpec.describe SendPaymentsJob do
  let(:period_start) { 2.weeks.ago }
  let(:period_end) { Date.today }

  subject { described_class.new.perform(period_start.to_s, period_end.to_s) }

  describe 'with unpaid payments' do
    let!(:payment) { FactoryGirl.create :payment, period_start: period_start, period_end: period_end,
      paid: false }

    it 'should update the payment as paid' do
      expect{subject}.to change{payment.reload.paid}.to true
    end
  end

end
