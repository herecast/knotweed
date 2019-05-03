# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Outreach::CreateMailchimpSegmentForNewUser do
  describe '::call' do
    before do
      @user = FactoryGirl.create :user
      @mc_id = 'n4k23jn3k2'
      @error_count = { 'error_count' => 0 }
      @lists_array = double(
        subscribe: true,
        static_segment_add: { 'id' => @mc_id },
        static_segment_members_add: @error_count,
        member_info: { 'success_count' => 0 }
      )
      mailchimp = double(lists: @lists_array)
      allow(Mailchimp::API).to receive(:new)
        .and_return(mailchimp)
      env = double(
        mailchimp_api_key: 'dummy',
        mailchimp_api_host: 'dummy'
      )
      allow(Figaro).to receive(:env).and_return(env)
    end

    subject { Outreach::CreateMailchimpSegmentForNewUser.call(@user) }

    it 'subscribes User to Master list' do
      expect(@lists_array).to receive(:subscribe).with(
        MailchimpAPI.config.master_list_id,
        { email: @user.email },
        nil,
        'html',
        false
      )
      subject
    end

    it 'it calls to Mailchimp to create User-specific segment' do
      expect { subject }.to change {
        @user.reload.mc_segment_id
      }.to @mc_id
    end

    it 'subscribes User to User-specific segment' do
      expect(@lists_array).to receive(:static_segment_members_add)
        .with(
          MailchimpAPI.config.master_list_id,
          @mc_id,
          [{ email: @user.email }]
        )
      subject
    end

    context 'when schedule_blogger_emails: true' do
      let(:organization) { FactoryGirl.create(:organization) }

      subject do
        Outreach::CreateMailchimpSegmentForNewUser.call(@user,
                                                        schedule_blogger_emails: true,
                                                        organization: organization)
      end

      it 'calls to schedule blogger emails' do
        expect(Outreach::ScheduleBloggerEmails).to receive(:call).with(
          action: 'blogger_welcome_and_reminder',
          user: @user,
          organization: organization
        )
        subject
      end
    end

    context 'when user already has mc_segment_id' do
      before do
        @user.update_attribute(:mc_segment_id, 'njknnj')
      end

      it 'does not create Mailchimp segment for user' do
        expect(MailchimpService::NewUser).not_to receive(:create_segment)
        expect(MailchimpService::NewUser).not_to receive(:add_to_segment)
        subject
      end
    end
  end
end
