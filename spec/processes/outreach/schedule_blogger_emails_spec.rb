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

    context "when action: blogger_welcome_and_reminder" do
      subject do
        Outreach::ScheduleBloggerEmails.call(
          action: 'blogger_welcome_and_reminder',
          user: @user,
          organization: @organization
        )
      end

      it "schedules initial email and follow-up email" do
        expect(@campaigns_array).to receive(:create).exactly(2).times
        expect { subject }.to change {
          @organization.reload.reminder_campaign_id
        }.to @campaign_id
      end
    end

    context "when action is for first or third post" do
      ['first_blogger_post', 'third_blogger_post'].each do |action|
        subject do
          Outreach::ScheduleBloggerEmails.call(
            action: action,
            user: @user,
            organization: @organization
          )
        end

        it "schedules an email" do
          expect(@campaigns_array).to receive(:create)
          subject
        end
      end
    end

    context "when blogger does not have mailchimp segment" do
      before do
        @user.update_attribute(:mc_segment_id, nil)
        allow(Outreach::CreateMailchimpSegmentForNewUser).to receive(
          'call'
        ).and_return true
      end

      subject do
        Outreach::ScheduleBloggerEmails.call(
          action: 'blogger_welcome_and_reminder',
          user: @user,
          organization: @organization
        )
      end

      it "creates mailchimp segment for user" do
        expect(Outreach::CreateMailchimpSegmentForNewUser).to receive(
          'call'
        ).with(@user, organization: @organization)
        subject
      end
    end
  end
end
