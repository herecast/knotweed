# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ConfirmRegistration do
  context 'Given a user comfirmation token' do
    let!(:user) { FactoryGirl.create :user, confirmed_at: nil }
    let!(:unconfirmed_subscription) { FactoryGirl.create :subscription, user_id: user.id, confirmed_at: nil, confirm_ip: nil }

    subject { described_class.call(confirmation_token: user.instance_variable_get(:@raw_confirmation_token), confirm_ip: '0.0.0.0.0') }

    it 'confirmed the user account' do
      expect { subject }.to change {
        user.reload.attributes.with_indifferent_access.slice(:confirmed_at)
      }.to a_hash_including(
        confirmed_at: an_instance_of(ActiveSupport::TimeWithZone)
      )
    end

    it 'confirms any unconfirmed subscriptions' do
      expect { subject }.to change {
        unconfirmed_subscription.reload.attributes.with_indifferent_access.slice(:confirm_ip, :confirmed_at)
      }.to a_hash_including(
        confirm_ip: '0.0.0.0.0',
        confirmed_at: an_instance_of(ActiveSupport::TimeWithZone)
      )
    end

    it 'returns a User' do
      return_value = subject
      expect(return_value).to be_an_instance_of(User)
    end

    it 'calls Mailchimp service to create custom User segment' do
      background_job = class_double('BackgroundJob').as_stubbed_const
      background_job = background_job.as_null_object
      expect(background_job).to receive(:perform_later).with(
        'Outreach::CreateMailchimpSegmentForNewUser',
        'call',
        user,
        schedule_welcome_emails: true
      )
      subject
    end

    context 'when user token is invalid' do
      it 'still returns a User if the confirmation_token is invalid' do
        return_value = ConfirmRegistration.call(confirmation_token: 'FAKETOKEN', confirm_ip: '0.0.0.0.0')
        expect(return_value).to be_an_instance_of(User)
      end
    end
  end
end
