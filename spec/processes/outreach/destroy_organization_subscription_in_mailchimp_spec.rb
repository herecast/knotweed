# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Outreach::CreateOrganizationSubscriptionInMailchimp do
  describe '::call' do
    before do
      @mc_segment_id = 'mc-ndjk21'
      @organization = FactoryGirl.create :organization, mc_segment_id: @mc_segment_id
      @user = FactoryGirl.create :user
      @org_subscription = FactoryGirl.create :organization_subscription,
                                             user_id: @user.id,
                                             organization_id: @organization.id
      @lists = double(static_segment_members_del: true)
      mailchimp = double(lists: @lists)
      allow(Mailchimp::API).to receive(:new).and_return(mailchimp)
      env = double(
        mailchimp_api_key: 'dummy'
      )
      allow(Figaro).to receive(:env).and_return(env)
    end

    subject do
      Outreach::DestroyOrganizationSubscriptionInMailchimp.call(@org_subscription)
    end

    it 'calls to Mailchimp to remove subscription' do
      expect(@lists).to receive(:static_segment_members_del).with(
        MailchimpAPI.config.master_list_id,
        @mc_segment_id,
        [{ email: @user.email }]
      )
      subject
    end

    it 'marks organization_subscription as deleted' do
      expect { subject }.to change {
        @org_subscription.reload.deleted_at
      }
    end
  end
end
