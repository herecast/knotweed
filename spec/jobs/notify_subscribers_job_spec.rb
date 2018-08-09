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

  let(:post)      { FactoryGirl.create(:content, :news, pubdate: 1.day.from_now) }

  it { expect(post.title            ).to be_present }
  it { expect(post.organization_name).to be_present }

  describe 'perform' do
    before do
      allow_any_instance_of(NotifySubscribersJob::SubscriberListIdFetcher).to receive(:call).and_return(69)
    end

    context "a viable post" do
      it "sends the campaign email" do
        expect(SubscriptionsMailchimpClient).to receive(:create_campaign).and_return("some-id")
        expect(SubscriptionsMailchimpClient).to receive(:update_campaign)
        expect(SubscriptionsMailchimpClient).to receive(:set_content)
        expect(@campaigns).to receive(:schedule)
        NotifySubscribersJob.new.perform(post)
      end
    end

    context "a post missing a subscriber list" do
      it "does nothing" do
        allow_any_instance_of(NotifySubscribersJob::SubscriberListIdFetcher).to receive(:call).and_return(nil)
        expect(SubscriptionsMailchimpClient).to_not receive(:create_campaign)
        NotifySubscribersJob.new.perform(post)
      end
    end

    context "a post that has already been been sent as a campaign" do
      before do
        expect(SubscriptionsMailchimpClient).to receive(:create_campaign).and_return("some-id")
        expect(SubscriptionsMailchimpClient).to receive(:update_campaign)
        expect(SubscriptionsMailchimpClient).to receive(:set_content)
        expect(@campaigns).to receive(:schedule)
        NotifySubscribersJob.new.perform(post)
      end

      it "does nothing" do
        expect(SubscriptionsMailchimpClient).to_not receive(:create_campaign)
        expect(SubscriptionsMailchimpClient).to_not receive(:update_campaign)
        expect(SubscriptionsMailchimpClient).to_not receive(:set_content)
        expect(@campaigns).not_to receive(:schedule)
        NotifySubscribersJob.new.perform(post)
      end
    end

    context "a post without a pubdate" do
      before do
        post.update_attribute(:pubdate, nil)
      end

      it "does not send a campaign email" do
        expect(SubscriptionsMailchimpClient).to_not receive(:create_campaign)
        expect(SubscriptionsMailchimpClient).to_not receive(:update_campaign)
        expect(SubscriptionsMailchimpClient).to_not receive(:set_content)
        expect(@campaigns).to_not receive(:schedule)
        NotifySubscribersJob.new.perform(post)
      end
    end
  end
end
