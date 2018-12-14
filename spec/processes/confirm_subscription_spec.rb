# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ConfirmSubscription do
  let(:confirm_ip) { '192.168.1.1' }
  let(:subscription) do
    FactoryGirl.create :subscription,
                       confirmed_at: nil,
                       confirm_ip: nil
  end

  subject { described_class.call(subscription, confirm_ip) }

  it 'sets confirm_ip and confirmed_at' do
    expect { subject }.to change {
      subscription.reload.attributes.with_indifferent_access.slice(:confirm_ip, :confirmed_at)
    }.to a_hash_including(
      confirm_ip: confirm_ip,
      confirmed_at: an_instance_of(ActiveSupport::TimeWithZone)
    )
  end

  context 'when subscription.listserv has mc_list_id' do
    before do
      subscription.listserv.update mc_list_id: '43q432', mc_group_name: 'blah'
    end

    it 'backgrounds MailchimpService.subscribe' do
      expect(BackgroundJob).to receive(:perform_later).with('MailchimpService', 'subscribe', subscription)
      subject
    end
  end

  context 'when subscription.listserv does not have mc_list_id' do
    before do
      subscription.listserv.update mc_list_id: nil, mc_group_name: nil
    end

    it 'does not background MailchimpService.subscribe' do
      expect(BackgroundJob).to_not receive(:perform_later).with('MailchimpService', 'subscribe', subscription)
      subject
    end
  end

  context 'when already confirmed' do
    before do
      subscription.update! confirmed_at: 1.day.ago, confirm_ip: '1.1.1.1'
    end

    it 'does not change confirmed_at, confirm_ip' do
      expect { subject }.to_not change {
        subscription.reload.attributes.with_indifferent_access.slice(
          :confirm_ip, :confirmed_at
        )
      }

      subject
    end

    context 'when previously subscription unsubscribed' do
      before do
        subscription.update! unsubscribed_at: Time.current
      end

      it 'unsets unsubscribed status' do
        expect { subject }.to change {
          subscription.reload.unsubscribed?
        }.to false
      end
    end
  end
end
