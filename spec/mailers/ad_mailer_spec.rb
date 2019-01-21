# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdMailer do
  let(:user) { FactoryGirl.create :user }

  describe '#event_advertising_user_contact' do
    subject { described_class.event_advertising_user_contact(user).deliver_now }

    it 'successfully delivers the email' do
      expect{subject}.to change {
        ActionMailer::Base.deliveries.count
      }.by(1)
    end
  end

  describe '#event_advertising_request' do
    let(:event) { FactoryGirl.create :content, :event }
    subject { described_class.event_advertising_request(user, event).deliver_now }

    it 'successfully delivers the email' do
      expect{subject}.to change {
        ActionMailer::Base.deliveries.count
      }.by(1)
    end
  end

  describe '#coupon_request' do
    let(:email) { 'test@test.com' }
    let(:promo_coupon) { FactoryGirl.create :promotion_banner }
    subject { described_class.coupon_request(email, promo_coupon).deliver_now }

    it 'successfully delivers the email' do
      expect{subject}.to change {
        ActionMailer::Base.deliveries.count
      }.by(1)
    end    
  end

  describe '#ad_sunsetting' do
    let(:promotion_banner) { FactoryGirl.create :promotion_banner }
    subject { described_class.ad_sunsetting(promotion_banner).deliver_now }

    it 'successfully delivers the email' do
      expect{subject}.to change {
        ActionMailer::Base.deliveries.count
      }.by(1)
    end    
  end
end
