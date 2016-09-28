require 'rails_helper'

RSpec.describe ConfirmSubscriptionAndNotify do
  let(:confirm_ip) { '192.168.1.1' }
  let(:subscription) {
    FactoryGirl.create :subscription,
      confirmed_at: nil,
      confirm_ip: nil
  }

  subject{ described_class.call(subscription, confirm_ip) }

  it 'runs ConfirmSubscription.call' do
    expect(ConfirmSubscription).to receive(:call).with(
      subscription,
      confirm_ip
    )

    subject
  end

  it 'sends subscription confirmation email' do
    expect(NotificationService).to receive(:subscription_confirmation).with(subscription)
    subject
  end

  context 'when already confirmed' do
    before do
      subscription.update! confirmed_at: 1.day.ago, confirm_ip: '1.1.1.1'
    end

    it 'does not send subscription confirmation email' do
      expect(NotificationService).to_not receive(:subscription_confirmation)
      subject
    end

    context 'when previously subscription unsubscribed' do
      before do
        subscription.update! unsubscribed_at: Time.current
      end

      it 'sends subscription confirmation email' do
        expect(NotificationService).to receive(:subscription_confirmation).with(subscription)
        subject
      end
    end

  end
end
