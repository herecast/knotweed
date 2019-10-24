# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Outreach::CreateOrganizationSubscriptionInMailchimp, elasticsearch: true do
  describe '::call' do
    before do
      @mc_segment_id = 'mc-ndjk21'
      @user = FactoryGirl.create :user
      @caster = FactoryGirl.create :caster, mc_followers_segment_id: @mc_segment_id
      @organization = FactoryGirl.create :organization, user_id: @caster.id
      @org_subscription = FactoryGirl.create :organization_subscription,
                                             user_id: @user.id,
                                             caster_id: @caster.id

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

    it "calls narrow reindex on Organization" do
      expect_any_instance_of(Organization).to receive(
        :reindex
      ).with(:active_subscriber_count_data)
      subject
    end
  end
end
