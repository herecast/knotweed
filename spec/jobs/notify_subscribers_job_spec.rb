require 'rails_helper'

RSpec.describe NotifySubscribersJob, type: :job do
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
        expect(SubscriptionsMailchimpClient).to receive(:unschedule_campaign)
        expect(SubscriptionsMailchimpClient).to receive(:schedule_campaign)
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
        expect(SubscriptionsMailchimpClient).to receive(:update_campaign)
        expect(SubscriptionsMailchimpClient).to receive(:set_content)
        expect(SubscriptionsMailchimpClient).to receive(:unschedule_campaign)
        expect(SubscriptionsMailchimpClient).to receive(:schedule_campaign)
        NotifySubscribersJob.new.perform(post.id)

        expect(SubscriptionsMailchimpClient).to receive(:get_status).and_return("sent")
      end

      it "does nothing" do
        expect(SubscriptionsMailchimpClient).to_not receive(:create_campaign)
        expect(SubscriptionsMailchimpClient).to_not receive(:update_campaign)
        expect(SubscriptionsMailchimpClient).to_not receive(:set_content)
        expect(SubscriptionsMailchimpClient).to_not receive(:unschedule_campaign)
        expect(SubscriptionsMailchimpClient).to_not receive(:schedule_campaign)
        NotifySubscribersJob.new.perform(post.id)
      end
    end

    context "a post that has already has an un-sent campaign" do
      before do
        expect(SubscriptionsMailchimpClient).to receive(:create_campaign).once.and_return("some-id")
        expect(SubscriptionsMailchimpClient).to receive(:update_campaign).twice
        expect(SubscriptionsMailchimpClient).to receive(:set_content).twice
        expect(SubscriptionsMailchimpClient).to receive(:unschedule_campaign).twice
        expect(SubscriptionsMailchimpClient).to receive(:schedule_campaign).twice
        NotifySubscribersJob.new.perform(post.id)

        expect(SubscriptionsMailchimpClient).to receive(:get_status).and_return("save")
      end

      it "cancels the un-sent campaign and changes the campaign identifier" do
        NotifySubscribersJob.new.perform(post.id)
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
        expect(SubscriptionsMailchimpClient).to_not receive(:unschedule_campaign)
        expect(SubscriptionsMailchimpClient).to_not receive(:schedule_campaign)
        NotifySubscribersJob.new.perform(post.id)
      end
    end

    context "a post whose pubdate is in the future" do
      before do
        post.update_attribute(:pubdate, 1.day.from_now)
      end

      it "schedules the campaign for a little bit past the pubdate" do
        expect(SubscriptionsMailchimpClient).to receive(:create_campaign).and_return("some-id")
        expect(SubscriptionsMailchimpClient).to receive(:update_campaign)
        expect(SubscriptionsMailchimpClient).to receive(:set_content)
        expect(SubscriptionsMailchimpClient).to receive(:unschedule_campaign)

        scheduled_time = nil
        allow(SubscriptionsMailchimpClient).to receive(:schedule_campaign) do |args|
          scheduled_time = args[:send_at]
        end
        NotifySubscribersJob.new.perform(post.id)
        expect((scheduled_time - post.pubdate) < 30.minutes)
      end
    end

    context "a post whose pubdate is in the past" do
      before do
        post.update_attribute(:pubdate, 1.day.ago)
      end

      it "schedules the campaign for a little bit in the future" do
        expect(SubscriptionsMailchimpClient).to receive(:create_campaign).and_return("some-id")
        expect(SubscriptionsMailchimpClient).to receive(:update_campaign)
        expect(SubscriptionsMailchimpClient).to receive(:set_content)
        expect(SubscriptionsMailchimpClient).to receive(:unschedule_campaign)

        scheduled_time = nil
        allow(SubscriptionsMailchimpClient).to receive(:schedule_campaign) do |args|
          scheduled_time = args[:send_at]
        end
        NotifySubscribersJob.new.perform(post.id)
        expect((scheduled_time - Time.now) < 30.minutes)
      end
    end
  end
end
