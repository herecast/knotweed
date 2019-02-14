# frozen_string_literal: true

require 'spec_helper'

describe Api::V3::PaymentsSerializer do
  let(:payment) { FactoryGirl.create :payment }
  let(:serializer_context) { {} }

  subject do
    JSON.parse(Api::V3::PaymentsSerializer.new(
      payment,
      root: false,
      context: serializer_context
    ).to_json)
  end

  it 'should successfully serialize the payment' do
    expect(subject).to be_present
  end

  %w[
    period_start
    period_end
    paid_impressions
    total_payment
    payment_date
    report_url
  ].each do |k|
    it "should serialize `#{k}`" do
      expect(subject.keys).to include k
    end
  end

  describe 'with user_id in context' do
    let(:serializer_context) { { user_id: FactoryGirl.create(:user).id } }

    it 'should include the user_id in `report_url`' do
      expect(subject['report_url']).to include("user_id=#{serializer_context[:user_id]}")
    end
  end
end
