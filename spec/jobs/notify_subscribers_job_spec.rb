require 'rails_helper'

RSpec.describe NotifySubscribersJob, type: :job do
  let(:post)  { FactoryGirl.create(:content, :news, pubdate: 1.day.from_now) }

  it { expect(post.title            ).to be_present }
  it { expect(post.author_name      ).to be_present }
  it { expect(post.organization_name).to be_present }

  describe 'perform' do
    before do
      allow_any_instance_of(NotifySubscribersJob::SubscriberListIdFetcher).to receive(:call).and_return(69)
    end

    context "a viable post" do
      it "sends the campaign email" do
        expect(SubscriptionsMailchimpClient).to receive(:create_campaign)
        expect(SubscriptionsMailchimpClient).to receive(:create_content)
        expect(SubscriptionsMailchimpClient).to receive(:schedule_campaign)
        NotifySubscribersJob.new.perform(post.id)
      end
    end

    context "a post missing a title" do
      it "does nothing" do
        post.update_attribute(:title, nil)
        expect(SubscriptionsMailchimpClient).to_not receive(:create_campaign)
        NotifySubscribersJob.new.perform(post.id)
      end
    end

    context "a post missing an author name" do
      it "does nothing" do
        post.update_attribute(:authors, nil)
        expect(SubscriptionsMailchimpClient).to_not receive(:create_campaign)
        NotifySubscribersJob.new.perform(post.id)
      end
    end

    context "a post missing an organization name" do
      it "does nothing" do
        post.organization.update_attribute(:name, nil)
        expect(SubscriptionsMailchimpClient).to_not receive(:create_campaign)
        NotifySubscribersJob.new.perform(post.id)
      end
    end

    context "a post missing a subscriber list" do
      it "does nothing" do
        allow_any_instance_of(NotifySubscribersJob::SubscriberListIdFetcher).to receive(:call).and_return(nil)
        expect(SubscriptionsMailchimpClient).to_not receive(:create_campaign)
        NotifySubscribersJob.new.perform(post.id)
      end
    end

    context "a post that has already been been sent as a campaign" do
      before do
        expect(SubscriptionsMailchimpClient).to receive(:create_campaign).and_return("some-id")
        expect(SubscriptionsMailchimpClient).to receive(:create_content)
        expect(SubscriptionsMailchimpClient).to receive(:schedule_campaign)
        NotifySubscribersJob.new.perform(post.id)

        expect(SubscriptionsMailchimpClient).to receive(:get_status).and_return("sent")
      end

      it "does nothing" do
        expect(SubscriptionsMailchimpClient).to_not receive(:create_campaign)
        NotifySubscribersJob.new.perform(post.id)
      end
    end

    context "a post that has already has an un-sent campaign" do
      before do
        expect(SubscriptionsMailchimpClient).to receive(:create_campaign).once.and_return("some-id")
        expect(SubscriptionsMailchimpClient).to receive(:create_content).twice
        expect(SubscriptionsMailchimpClient).to receive(:schedule_campaign).twice
        NotifySubscribersJob.new.perform(post.id)

        expect(SubscriptionsMailchimpClient).to receive(:get_status).and_return("save")
      end

      it "cancels the un-sent campaign and changes the campaign identifier" do
        expect(post.reload.subscriber_mc_identifier).to eq "some-id"
        expect(SubscriptionsMailchimpClient).to receive(:cancel_campaign).with(campaign_identifier: "some-id")
        expect(SubscriptionsMailchimpClient).to receive(:create_campaign).once.and_return("some-new-id")
        NotifySubscribersJob.new.perform(post.id)
        expect(post.reload.subscriber_mc_identifier).to eq "some-new-id"
      end
    end

    context "a post without a pubdate" do
      before do
        post.update_attribute(:pubdate, nil)
      end

      it "sends the campaign email" do
        expect(SubscriptionsMailchimpClient).to receive(:create_campaign)
        expect(SubscriptionsMailchimpClient).to receive(:create_content)
        expect(SubscriptionsMailchimpClient).to receive(:send_campaign)
        NotifySubscribersJob.new.perform(post.id)
      end
    end
  end
end
