# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GeneratePayments, freeze_time: true do
  let(:period_start) { Date.today - 1.month }
  let(:period_end) { Date.today }
  let(:period_ad_rev) { 3500.10 }

  subject { described_class.call(period_start: period_start.to_s, period_end: period_end.to_s, period_ad_rev: period_ad_rev) }

  describe 'with no payment recipients' do
    it 'should not create any payments' do
      expect { subject }.to_not change { Payment.count }
    end
  end

  describe 'with payment recipient' do
    let!(:recipient) { FactoryGirl.create :payment_recipient }

    describe 'with no ad impressions' do
      it 'should not create any payments' do
        expect { subject }.to_not change { Payment.count }
      end
    end

    describe 'with valid ad impressions *not* in the period' do
      let(:included_content) { FactoryGirl.create :content, created_by: recipient.user }
      let!(:impression_out_of_period) do
        FactoryGirl.create :promotion_banner_metric, content: included_content,
                                                     created_at: (period_start - 1.month)
      end

      it 'should not create any payments' do
        expect { subject }.to_not change { Payment.count }
      end
    end

    describe 'with valid ad impressions on two contents' do
      let(:included_content1) { FactoryGirl.create :content, created_by: recipient.user }
      let(:included_content2) { FactoryGirl.create :content, created_by: recipient.user }
      let!(:impression1) do
        FactoryGirl.create :promotion_banner_metric, content: included_content1,
                                                     created_at: (period_end - 2.days)
      end
      let!(:impression2) do
        FactoryGirl.create :promotion_banner_metric, content: included_content2,
                                                     created_at: (period_end - 2.days)
      end

      it 'should create two payments' do
        expect { subject }.to change { Payment.count }.by(2)
      end

      it 'should assign payments to the user' do
        subject
        expect(Payment.last.paid_to).to eq recipient.user
      end
    end
  end
end
