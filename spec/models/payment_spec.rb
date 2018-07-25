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

  describe 'Payment.by_period' do
    let!(:payment1) { FactoryGirl.create :payment }
    let!(:payment2) { FactoryGirl.create :payment,
      period_start: payment1.period_start,
      period_end: payment1.period_end
    }

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
