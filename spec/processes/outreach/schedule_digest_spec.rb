require 'spec_helper'

RSpec.describe Outreach::ScheduleDigest do
  before do
    @listserv = FactoryGirl.create :listserv
    @digest = Outreach::BuildDigest.call(@listserv)
    @digest.save
    allow(MailchimpService).to receive(:create_campaign).and_return(
      { id: 'fake-id'}
    )
  end

  describe "::call" do
    subject { Outreach::ScheduleDigest.call(@digest) }

    it "makes call to schedule digest" do
      expect(BackgroundJob).to receive(:perform_later).with(
        'Outreach::ScheduleDigest', 'send_campaign', @digest
      )
      subject
    end
  end

  describe "::send_campaign" do
    before do
      allow(MailchimpService).to receive(:send_campaign).and_return(true)
    end

    subject { Outreach::ScheduleDigest.send_campaign(@digest) }

    it "sends campaign" do
      expect{ subject }.to change{
        @digest.reload.sent_at
      }.and change{
        @listserv.reload.last_digest_send_time
      }
    end
  end
end