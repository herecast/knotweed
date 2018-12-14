# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubscribeToListserv do
  context 'Given a listserv and attrs including email;' do
    let(:attrs) do
      {
        email: 'user@example.org',
        name: 'tom dale',
        source: 'email'
      }
    end
    let(:listserv) { FactoryGirl.create :subtext_listserv }

    subject { SubscribeToListserv.call(listserv, attrs) }

    it 'creates a subscription' do
      subscription = subject
      expect(subscription.valid?).to be true
      expect(subscription.persisted?).to be true
      expect(subscription.listserv).to eql listserv
      expect(subscription.email).to eql attrs[:email]
      expect(subscription.name).to eql attrs[:name]
      expect(subscription.source).to eql attrs[:source]
    end

    it 'sends subscription verification' do
      expect(NotificationService).to receive(:subscription_verification).with(instance_of(Subscription))
      subject
    end

    context 'when existing subscription;' do
      let!(:existing) do
        Subscription.create!(
          listserv: listserv,
          email: attrs[:email]
        )
      end

      it 'returns same subscription model' do
        subscription = subject
        expect(subscription.id).to eql existing.id
      end

      context 'when already confirmed' do
        before do
          existing.update!(
            confirmed_at: Time.zone.now,
            confirm_ip: '1.1.1.1'
          )
        end

        it 'sends existing subscription email' do
          expect(NotificationService).to receive(:existing_subscription).with(instance_of(Subscription))
          subject
        end
        it 'does not send subscription verification' do
          expect(NotificationService).to_not receive(:subscription_verification).with(instance_of(Subscription))
          subject
        end
      end

      context 'when not confirmed' do
        before do
          existing.update! confirmed_at: nil
        end

        it 'does not send existing subscription email' do
          expect(NotificationService).to_not receive(:existing_subscription).with(instance_of(Subscription))
          subject
        end
        it 'does send subscription verification' do
          expect(NotificationService).to receive(:subscription_verification).with(instance_of(Subscription))
          subject
        end
      end

      context 'when previously unsubscribed;' do
        before do
          existing.update_attribute(:unsubscribed_at, Time.zone.now)
        end

        it 'changes unsubscribed status to subscribed' do
          expect do
            subject
          end.to change {
            existing.reload.unsubscribed?
          }.from(true).to(false)
        end
      end
    end
  end
end
