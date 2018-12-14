# frozen_string_literal: true

# == Schema Information
#
# Table name: payments
#
#  id                 :integer          not null, primary key
#  period_start       :date
#  period_end         :date
#  paid_impressions   :integer
#  pay_per_impression :decimal(, )
#  total_payment      :decimal(, )
#  payment_date       :date
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  content_id         :integer
#  paid_to            :integer
#  paid               :boolean          default(FALSE)
#
# Indexes
#
#  index_payments_on_paid_to  (paid_to)
#
# Foreign Keys
#
#  fk_rails_...  (content_id => contents.id)
#

require 'rails_helper'

RSpec.describe Payment, type: :model do
  describe 'Payment.for_user(user_id)' do
    let(:user) { FactoryGirl.create :user }
    let(:content) { FactoryGirl.create :content, created_by: user }
    let!(:payment) { FactoryGirl.create :payment, content: content, paid_to: user }
    let!(:other_payment) { FactoryGirl.create :payment }

    subject { Payment.for_user(user.id) }

    it 'should return payments belonging to content created by that user' do
      expect(subject).to match_array([payment])
    end
  end

  describe 'Payment.by_user' do
    let(:user) { FactoryGirl.create :user }
    let!(:payment) { FactoryGirl.create :payment, period_start: 1.week.ago, period_end: Date.today, paid_to: user }
    let!(:payment2) { FactoryGirl.create :payment, period_start: 1.week.ago, period_end: Date.today, paid_to: user }
    let!(:payment3) { FactoryGirl.create :payment, period_start: 1.month.ago, period_end: 3.weeks.ago, paid_to: user }
    let!(:other_user_payment) { FactoryGirl.create :payment } # a different user

    subject { Payment.by_user }

    it 'should return one entry for every user pay period' do
      expect(subject.length).to eq 3
    end

    it 'should sum the total payment per user period' do
      expect(subject.map(&:total_payment)).to match_array([payment.total_payment + payment2.total_payment, payment3.total_payment, other_user_payment.total_payment])
    end
  end

  describe 'Payment.to_csv' do
    let!(:payment) { FactoryGirl.create :payment }

    subject { Payment.to_csv }

    it 'should export to CSV' do
      invoice_date = payment.period_end.next_month.beginning_of_month
      expect(subject).to eql(
        "Vendor Name,Invoice #,Invoice Date,Due Date,Amount,Account\n" \
        "#{payment.paid_to.fullname},#{payment.id},#{invoice_date},#{invoice_date + 9.days},#{payment.total_payment},#{BillDotComService::CHART_OF_ACCOUNT_ID}\n"
      )
    end
  end

  describe 'Payment.by_period' do
    let!(:payment1) { FactoryGirl.create :payment }
    let!(:payment2) do
      FactoryGirl.create :payment,
                         period_start: payment1.period_start,
                         period_end: payment1.period_end
    end

    subject { Payment.by_period }

    it 'should return one entry for every pay period' do
      expect(subject.length).to eq 1
    end

    it 'should sum the total_payment per period' do
      expect(subject.first.total_payment).to eq(payment1.total_payment + payment2.total_payment)
    end

    it 'should sum the paid impressions per period' do
      expect(subject.first.paid_impressions).to eq(payment1.paid_impressions + payment2.paid_impressions)
    end
  end
end
