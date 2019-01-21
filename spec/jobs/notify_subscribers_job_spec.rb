# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NotifySubscribersJob, type: :job do
  before do
    lists_array = double(
      list: { 'data' => [{ 'stats' => { 'member_count' => 1 } }] }
    )
    @campaigns = double(schedule: true)
    mailchimp = double(lists: lists_array, campaigns: @campaigns)
    allow(Mailchimp::API).to receive(:new)
      .and_return(mailchimp)
  end

  let(:post) { FactoryGirl.create(:content, :news, pubdate: 1.day.from_now) }

  it { expect(post.title).to be_present }
  it { expect(post.organization_name).to be_present }

  describe 'perform' do
    before do
      allow_any_instance_of(NotifySubscribersJob).to receive(:fetch_subscriber_list_id).and_return(69)
    end

    context 'a viable post' do
      it 'sends the campaign email' do
        expect(SubscriptionsMailchimpClient).to receive(:create_campaign).and_return('some-id')
        expect(SubscriptionsMailchimpClient).to receive(:update_campaign)
        expect(SubscriptionsMailchimpClient).to receive(:set_content)
        expect(@campaigns).to receive(:schedule)
        NotifySubscribersJob.new.perform(post)
      end
    end

    context 'a post missing a subscriber list' do
      it 'does nothing' do
        allow_any_instance_of(NotifySubscribersJob).to receive(:fetch_subscriber_list_id).and_return(nil)
        expect(SubscriptionsMailchimpClient).to_not receive(:create_campaign)
        NotifySubscribersJob.new.perform(post)
      end
    end

    context 'a post that has already been been sent as a campaign' do
      before do
        expect(SubscriptionsMailchimpClient).to receive(:create_campaign).and_return('some-id')
        expect(SubscriptionsMailchimpClient).to receive(:update_campaign)
        expect(SubscriptionsMailchimpClient).to receive(:set_content)
        expect(@campaigns).to receive(:schedule)
        NotifySubscribersJob.new.perform(post)
      end

      it 'does nothing' do
        expect(SubscriptionsMailchimpClient).to_not receive(:create_campaign)
        expect(SubscriptionsMailchimpClient).to_not receive(:update_campaign)
        expect(SubscriptionsMailchimpClient).to_not receive(:set_content)
        expect(@campaigns).not_to receive(:schedule)
        NotifySubscribersJob.new.perform(post)
      end
    end

    context 'a post without a pubdate' do
      before do
        post.update_attribute(:pubdate, nil)
      end

      it 'does not send a campaign email' do
        expect(SubscriptionsMailchimpClient).to_not receive(:create_campaign)
        expect(SubscriptionsMailchimpClient).to_not receive(:update_campaign)
        expect(SubscriptionsMailchimpClient).to_not receive(:set_content)
        expect(@campaigns).to_not receive(:schedule)
        NotifySubscribersJob.new.perform(post)
      end
    end
  end

  describe '#campaign_subject' do
    subject{ NotifySubscribersJob.new.send(:campaign_subject, post) }
    context 'for feature notification' do
      before { post.organization.update feature_notification_org: true }

      it 'should have the correct subject' do
        expect(subject).to eq "New DailyUV Features!"
      end
    end
  end

  describe '#appropriate_template_path' do
    subject{ NotifySubscribersJob.new.send(:appropriate_template_path, post) }

    context 'for feature notification' do
      before { post.organization.update feature_notification_org: true }

      it 'should have the correct path' do
        expect(subject).to eq NotifySubscribersJob::ERB_FEATURE_NOTIFICATION_TEMPLATE_PATH
      end
    end

    context 'for event/market/talk' do
      let(:post) { FactoryGirl.create(:content, :market_post, pubdate: 1.day.from_now) }

      it 'should have the correct path' do
        expect(subject).to eq NotifySubscribersJob::ERB_NON_NEWS_POST_TEMPLATE_PATH
      end
    end
  end

  describe '#notification_already_sent' do
    subject{ NotifySubscribersJob.new.send(:notification_already_sent, post) }

    context 'with no `subscriber_mc_identifier`' do
      let(:post) { FactoryGirl.create(:content, :news, pubdate: 1.day.from_now, subscriber_mc_identifier: nil) }

      it { expect(subject).to be_falsy }
    end

    context 'with `subscriber_mc_identifier` populated' do
      let(:post) { FactoryGirl.create(:content, :news, pubdate: 1.day.from_now, subscriber_mc_identifier: 'fakeID') }

      context 'with status sent' do
        before { allow(SubscriptionsMailchimpClient).to receive(:get_status).with({campaign_identifier: post.subscriber_mc_identifier}).and_return('sent') }

        it { expect(subject).to be_truthy }
      end

      context 'with other non-sent status' do
        before { allow(SubscriptionsMailchimpClient).to receive(:get_status).with({campaign_identifier: post.subscriber_mc_identifier}).and_return('OTHERSTATUS') }

        it { expect(subject).to be_falsy }
      end
    end
  end

  describe '#fetch_subscriber_list_id' do
    let(:org) { FactoryGirl.create :organization, subscribe_url: subscribe_url }
    subject{ NotifySubscribersJob.new.send(:fetch_subscriber_list_id, org) }

    context 'for an org with no subscribe_url' do
      let(:subscribe_url) { nil }
      it { expect(subject).to be_nil }
    end

    context 'for an org with a subscribe_url' do
      let(:subscribe_url) { 'fakesubscribeurl.com' }

      context 'that matches the list of urls' do
        before{ allow(SubscriptionsMailchimpClient).to receive(:lists).and_return [
          {
            'name' => 'test',
            'subscribe_url_short' => subscribe_url,
            'id' => 123
          }
        ]}

        it 'should return the id of the matching list' do
          expect(subject).to eql 123
        end
      end

      context 'that does not match the list of urls but matches name' do
        let(:subscribe_url) { 'blahblah.com' }

        before{ allow(SubscriptionsMailchimpClient).to receive(:lists).and_return [
          {
            'name' => org.name,
            'subscribe_url_short' => 'someotherurl.com',
            'id' => 123
          }
        ]}

        it 'should return the id of the matching list' do
          expect(subject).to eql 123
        end
      end

      context 'with no matching url or name' do
        let(:subscribe_url) { 'blahblah.com' }
        before { allow(SubscriptionsMailchimpClient).to receive(:lists).and_return [] }

        it 'should return false' do
          expect(subject).to be_falsy
        end
      end
    end
  end
end
