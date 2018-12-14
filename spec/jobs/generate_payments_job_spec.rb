require 'rails_helper'

RSpec.describe GeneratePaymentsJob do
  let(:period_start) { 2.weeks.ago }
  let(:period_end) { Date.today }
  let(:period_ad_rev) { 3554.23 }

  subject { described_class.new.perform(period_start.to_s, period_end.to_s, period_ad_rev) }

  it 'should call GeneratePayments' do
    expect(GeneratePayments).to receive(:call).with({ period_start: period_start.to_s, period_end: period_end.to_s,
                                                      period_ad_rev: period_ad_rev })
    subject
  end
end
