require 'rails_helper'

RSpec.describe NotifySubscribersJob, type: :job do
  let(:post)  { FactoryGirl.create(:content, :news) }

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
        expect(SubscriptionsMailchimpClient).to receive(:send_campaign)
        NotifySubscribersJob.new.perform(post)
      end
    end

    context "a post missing a title" do
      it "does nothing" do
        post.title = nil
        expect(SubscriptionsMailchimpClient).to_not receive(:create_campaign)
        NotifySubscribersJob.new.perform(post)
      end
    end

    context "a post missing an author name" do
      it "does nothing" do
        post.authors = nil
        expect(SubscriptionsMailchimpClient).to_not receive(:create_campaign)
        NotifySubscribersJob.new.perform(post)
      end
    end

    context "a post missing an organization name" do
      it "does nothing" do
        post.organization.name = nil
        expect(SubscriptionsMailchimpClient).to_not receive(:create_campaign)
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
  end
end
