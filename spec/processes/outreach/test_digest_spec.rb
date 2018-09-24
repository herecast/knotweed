require 'spec_helper'

RSpec.describe Outreach::TestDigest do
  before do
    @list_id = 'fake-list-id'
    @campaign_id = 'fake-campaign-id'
  end

  describe "::call" do
    before do
      @listserv = FactoryGirl.create :listserv
      @digest = Outreach::BuildDigest.call(@listserv)
      @digest.save
      @user = FactoryGirl.create :user
      allow(MailchimpService::UserOutreach).to receive(:create_list).and_return(
        { 'id' => @list_id }
      )
      allow(MailchimpService::UserOutreach).to receive(:subscribe_user_to_list).and_return(
        true
      )
      allow(MailchimpService::UserOutreach).to receive(:create_test_campaign).and_return(
        { 'id' => @campaign_id }
      )
      allow(MailchimpService).to receive(:put_campaign_content).and_return(
        true
      )
      @background_job = double(perform_later: true)
      allow(BackgroundJob).to receive(:set).and_return(@background_job)
    end

    subject do
      Outreach::TestDigest.call(
        digest: @digest,
        user: @user
      )
    end

    it "builds list, subscribes user to list, builds campaign and calls to send campaign" do
      expect(MailchimpService::UserOutreach).to receive(:create_list)
      expect(MailchimpService::UserOutreach).to receive(:subscribe_user_to_list).with(
        list_id: @list_id,
        user: @user
      )
      expect(MailchimpService::UserOutreach).to receive(:create_test_campaign).with(
        list_id: @list_id,
        digest: @digest
      )
      expect(MailchimpService).to receive(:put_campaign_content).with(
        @campaign_id,
        any_args
      )
      expect(@background_job).to receive(:perform_later).with(
        'Outreach::TestDigest',
        'send_campaign',
        @campaign_id,
        @list_id
      )
      subject
    end
  end

  describe "::send_campaign" do
    before do
      allow(MailchimpService).to receive(:send_campaign).and_return(true)
      @background_job = double(perform_later: true)
      allow(BackgroundJob).to receive(:set).and_return(@background_job)
    end

    subject { Outreach::TestDigest.send_campaign(@campaign_id, @list_id) }

    it "sends campaign and calls to delete list and campaign" do
      expect(MailchimpService).to receive(:send_campaign).with(@campaign_id)
      expect(@background_job).to receive(:perform_later).with(
        'Outreach::TestDigest',
        'clean_up_campaign',
        @campaign_id,
        @list_id
      )
      subject
    end
  end

  describe "::clean_up_campaign" do
    before do
      allow(MailchimpService::UserOutreach).to receive(:delete_campaign).and_return(true)
      allow(MailchimpService::UserOutreach).to receive(:delete_list).and_return(true)
    end

    subject { Outreach::TestDigest.clean_up_campaign(@campaign_id, @list_id) }

    it "deletes campaign and list" do
      expect(MailchimpService::UserOutreach).to receive(:delete_campaign).with(
        @campaign_id
      )
      expect(MailchimpService::UserOutreach).to receive(:delete_list).with(
        @list_id
      )
      subject
    end
  end
end