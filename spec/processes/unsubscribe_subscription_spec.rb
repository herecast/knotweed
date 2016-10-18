require 'rails_helper'

RSpec.describe UnsubscribeSubscription do
  let(:subscription) { FactoryGirl.create :subscription }

  subject { UnsubscribeSubscription.call(subscription) }

  it 'sets #unsubscribed_at' do
    expect{ subject }.to change{
      subscription.reload.unsubscribed_at
    }.to an_instance_of(ActiveSupport::TimeWithZone)
  end

  context 'when subscription.listserv has mc_list_id' do
    before do
      subscription.listserv.update mc_list_id: '43q432', mc_group_name: 'blah'
    end

    it 'backgrounds MailchimpService.unsubscribe' do
      expect(BackgroundJob).to receive(:perform_later).with(
        'MailchimpService', 'unsubscribe', subscription
      )
      subject
    end
  end

  context 'when subscription.listserv does not have mc_list_id' do
    before do
      subscription.listserv.update mc_list_id: nil, mc_group_name: nil
    end

    it 'does not run MailchimpService.unsubscribe' do
      expect(BackgroundJob).to_not receive(:perform_later).with(
        'MailchimpService', 'unsubscribe', subscription
      )
      subject
    end
  end


  context 'when unsubscribed;' do
    before do
      subscription.update unsubscribed_at: 1.day.ago
    end

    it 'does not change unsubscribed_at time' do
      expect{ subject }.to_not change{
        subscription.reload.unsubscribed_at
      }
    end
  end
end
