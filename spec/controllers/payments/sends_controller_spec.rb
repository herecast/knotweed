require 'spec_helper'

describe Payments::SendsController, type: :controller do
  let(:admin) { FactoryGirl.create :admin }
  before { sign_in admin }

  describe 'POST #create' do
    let(:period_start) { 2.weeks.ago.strftime('%m/%d/%Y') }
    let(:period_end) { Date.today.strftime('%m/%d/%Y') }

    subject { post :create, params: { period_start: period_start, period_end: period_end } }

    it 'should queue SendPaymentsJob' do
      subject
      expect(SendPaymentsJob).to have_been_enqueued.with(period_start, period_end)
    end
  end
end
