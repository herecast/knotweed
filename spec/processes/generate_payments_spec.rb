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

  describe 'with organization payment recipient' do
    let(:pay_for_org) { FactoryGirl.create :organization, pay_for_content: true }
    let!(:recipient) { FactoryGirl.create :payment_recipient, organization: pay_for_org }

    describe 'with no ad impressions' do
      it 'should not create any payments' do
        expect { subject }.to_not change { Payment.count }
      end
    end

    describe 'with child organizations with content' do
      let(:child_org) { FactoryGirl.create :organization, pay_for_content: true, parent: pay_for_org }
      let(:included_content1) { FactoryGirl.create :content, organization: child_org }
      let!(:promotion_metrics) do
        FactoryGirl.create_list :promotion_banner_metric, 3, content: included_content1,
                                                             created_at: 2.days.ago
      end

      it 'should create a payment record' do
        expect { subject }.to change { Payment.count }.by(1)
      end

      it 'should correctly assign the payment attributes' do
        subject
        payment = Payment.last
        expect(
          total_payment: payment.total_payment.to_f,
          period_start: payment.period_start,
          period_end: payment.period_end,
          payment_date: payment.payment_date,
          pay_per_impression: payment.pay_per_impression.truncate(4),
          paid_impressions: payment.paid_impressions,
          content_id: payment.content_id,
          paid_to: payment.paid_to
        ).to eq(
          total_payment: period_ad_rev,
          period_start: period_start,
          period_end: period_end,
          payment_date: period_end.next_month.beginning_of_month + 9.days,
          pay_per_impression: (period_ad_rev.to_f / promotion_metrics.count).to_d.truncate(4),
          paid_impressions: promotion_metrics.count,
          content_id: included_content1.id,
          paid_to: recipient.user
        )
      end
    end
  end

  describe 'with user payment recipient' do
    let(:pay_for_org) { FactoryGirl.create :organization, pay_for_content: true }
    let!(:recipient) { FactoryGirl.create :payment_recipient, organization: nil }

    describe 'with no ad impressions' do
      it 'should not create any payments' do
        expect { subject }.to_not change { Payment.count }
      end
    end

    describe 'with valid ad impressions *not* in the period' do
      let(:included_content) { FactoryGirl.create :content, created_by: recipient.user, organization: pay_for_org }
      let!(:impression_out_of_period) do
        FactoryGirl.create :promotion_banner_metric, content: included_content,
                                                     created_at: (period_start - 1.month)
      end

      it 'should not create any payments' do
        expect { subject }.to_not change { Payment.count }
      end
    end

    describe 'with valid ad impressions for an organization that is not paid' do
      let(:no_pay_org) { FactoryGirl.create :organization, pay_for_content: false }
      let(:included_content) { FactoryGirl.create :content, created_by: recipient.user, organization: no_pay_org }
      let!(:impression_out_of_period) do
        FactoryGirl.create :promotion_banner_metric, content: included_content,
                                                     created_at: (period_end - 2.days)
      end

      it 'should not create any payments' do
        expect { subject }.to_not change { Payment.count }
      end
    end

    describe 'with valid ad impressions on two contents' do
      let(:included_content1) { FactoryGirl.create :content, created_by: recipient.user, organization: pay_for_org }
      let(:included_content2) { FactoryGirl.create :content, created_by: recipient.user, organization: pay_for_org }
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
