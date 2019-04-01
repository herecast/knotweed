# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Outreach::AddUserToMailchimpMasterList do
  describe '::call' do
    before do
      @user = FactoryGirl.create :user
      @lists = double(
        subscribe: true,
        static_segment_members_add: true
      )
      mailchimp = double(lists: @lists)
      allow(Mailchimp::API).to receive(:new).and_return(mailchimp)
    end

    subject { Outreach::AddUserToMailchimpMasterList.call(@user) }

    it 'adds user to mailchimp list and new_user segment' do
      expect(@lists).to receive(:subscribe).with(
        Figaro.env.mailchimp_master_list_id,
        {
          email: @user.email
        },
        nil,
        'html',
        false
      )
      expect(@lists).to receive(:static_segment_members_add).with(
        Figaro.env.mailchimp_master_list_id,
        Figaro.env.mailchimp_new_user_segment_id,
        [{
          email: @user.email
        }]
      )
      subject
    end

    context 'when new_blogger: true' do
      subject do
        Outreach::AddUserToMailchimpMasterList.call(@user, new_blogger: true)
      end

      it 'adds user to new_blogger segment' do
        expect(@lists).to receive(:static_segment_members_add).with(
          Figaro.env.mailchimp_master_list_id,
          Figaro.env.mailchimp_new_blogger_segment_id,
          [{
            email: @user.email
          }]
        )
        subject
      end
    end
  end
end
