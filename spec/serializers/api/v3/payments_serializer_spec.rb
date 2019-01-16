# frozen_string_literal: true

require 'spec_helper'

describe Api::V3::PaymentsSerializer do
  let(:payment) { FactoryGirl.create :payment }

  subject do
    JSON.parse(Api::V3::PaymentsSerializer.new(
      payment,
      root: false,
      context: {}
    ).to_json)
  end

  it 'should successfully serialize the payment' do
    expect(subject).to be_present
  end

  %w[
    period_start
    period_end
    paid_impressions
    pay_per_impression
    total_payment
    payment_date
    report_url
    revenue_share
  ].each do |k|
    it "should serialize `#{k}`" do
      expect(subject.keys).to include k
    end
  end
end
