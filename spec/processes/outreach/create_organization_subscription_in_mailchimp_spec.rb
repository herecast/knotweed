# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Outreach::CreateOrganizationSubscriptionInMailchimp, elasticsearch: true do
  describe '::call' do
    before do
      @mc_segment_id = 'mc-83j29'
      @caster = FactoryGirl.create :caster
      @organization = FactoryGirl.create :organization, user_id: @caster.id
      @user = FactoryGirl.create :user
      @org_subscription = FactoryGirl.build :organization_subscription,
                                            user_id: @user.id,
                                            caster_id: @caster.id

      @lists = double(
        static_segment_add: { 'id' => @mc_segment_id },
        member_info: { 'success_count' => 0 },
        subscribe: true,
        static_segment_members_add: true
      )
      mailchimp = double(lists: @lists)
      allow(Mailchimp::API).to receive(:new).and_return(mailchimp)
      env = double(
        mailchimp_api_key: 'dummy',
        mailchimp_api_host: 'dummy'
      )
      allow(Figaro).to receive(:env).and_return(env)
    end

    subject do
      Outreach::CreateOrganizationSubscriptionInMailchimp.call(@org_subscription)
    end

    it 'creates mailchimp_segment_id for Organization' do
      expect { subject }.to change {
        @caster.reload.mc_followers_segment_id
      }.to @mc_segment_id
    end

    it 'ensures user is on Mailchimp master list' do
      expect(@lists).to receive(:member_info).with(
        MailchimpAPI.config.master_list_id,
        [{ email: @user.email }]
      )
      subject
    end

    it 'calls to subscribe user to Mailchimp list' do
      expect(@lists).to receive(:subscribe).with(
        MailchimpAPI.config.master_list_id,
        { email: @user.email },
        nil,
        'html',
        false
      )
      subject
    end

    it "calls for narrow reindex of Organization" do
      expect_any_instance_of(Organization).to receive(:reindex)
      subject
    end

    context 'when Caster has mc_followers_segment_id' do
      before do
        @caster.update_attribute(:mc_followers_segment_id, @mc_segment_id)
      end

      it 'does not add segment to master Mailchimp list' do
        expect(@lists).not_to receive(:static_segment_add)
        subject
      end
    end

    context 'when organization_subscription is persisted and deleted' do
      before do
        @org_subscription.deleted_at = Time.current
        @org_subscription.save
      end

      it 'updates deleted_at to nil' do
        expect { subject }.to change {
          @org_subscription.deleted_at
        }.to nil
      end
    end
  end
end
