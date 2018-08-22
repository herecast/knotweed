require 'spec_helper'

RSpec.describe Outreach::CreateMailchimpSegmentForNewUser do

  describe "::call" do
    before do
      @user = FactoryGirl.create :user
      @mc_id = 'n4k23jn3k2'
      @error_count = { 'error_count' => 0 }
      @lists_array = double(
        subscribe: true,
        static_segment_add: { "id" => @mc_id },
        static_segment_members_add: @error_count
      )
      mailchimp = double(lists: @lists_array)
      allow(Mailchimp::API).to receive(:new)
        .and_return(mailchimp)
    end

    subject { Outreach::CreateMailchimpSegmentForNewUser.call(@user) }

    it 'subscribes User to New User list' do
      expect(@lists_array).to receive(:subscribe).with(
        Rails.configuration.subtext.email_outreach.new_user_list_id,
        { email: @user.email },
        nil,
        'html',
        false
      )
      subject
    end

    it 'it calls to Mailchimp to create User-specific segment' do
      expect{ subject }.to change{
        @user.reload.mc_segment_id
      }.to @mc_id
    end

    it 'subscribes User to User-specific segment' do
      @user.update_attribute(:mc_segment_id, @mc_id)
      expect(@lists_array).to receive(:static_segment_members_add)
        .with(
          Rails.configuration.subtext.email_outreach.new_user_list_id,
          @mc_id,
          [{ email: @user.email }]
        )
      subject
    end

    context "when schedule_welcome_emails: true" do
      subject { Outreach::CreateMailchimpSegmentForNewUser.call(@user, schedule_welcome_emails: true) }
    
      it "calls to schedule welcome emails" do
        expect(Outreach::ScheduleWelcomeEmails).to receive(:call).with(
          @user
        )
        subject
      end
    end

    context "when schedule_blogger_emails: true" do
      let(:organization) { FactoryGirl.create(:organization) }

      subject do
        Outreach::CreateMailchimpSegmentForNewUser.call(@user,
          schedule_blogger_emails: true,
          organization: organization
        )
      end

      it "calls to schedule blogger emails" do
        expect(Outreach::ScheduleBloggerEmails).to receive(:call).with(
          user: @user,
          organization: organization
        )
        subject
      end
    end
  end
end