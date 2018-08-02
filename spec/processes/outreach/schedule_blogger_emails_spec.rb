require 'spec_helper'

RSpec.describe Outreach::ScheduleBloggerEmails do

  describe "::call" do
    before do
      @user = FactoryGirl.create :user,
        mc_segment_id: '43nj2k4'
      @organization = FactoryGirl.create :organization
      @campaign_id = '43n2hjb4'
      @campaigns_array = double(
        create: { 'id' => @campaign_id },
        schedule: true
      )
      mailchimp = double(campaigns: @campaigns_array)
      allow(Mailchimp::API).to receive(:new)
        .and_return(mailchimp)
    end

    subject { Outreach::ScheduleBloggerEmails.call(user: @user, organization: @organization) }
  
    it "schedules initial email and follow-up email" do
      expect(@campaigns_array).to receive(:create).exactly(2).times
      expect{ subject }.to change{
        @organization.reload.reminder_campaign_id
      }.to @campaign_id
    end
  end
end