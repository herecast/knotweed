# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Outreach::CreateOrganizationSubscriptionInMailchimp do

  describe "::call" do
    before do
      @master_list_id = Rails.configuration.subtext.email_outreach.new_user_list_id
      @organization = FactoryGirl.create :organization
      @user = FactoryGirl.create :user
      @org_subscription = FactoryGirl.build :organization_subscription,
        user_id: @user.id,
        organization_id: @organization.id
      @mc_segment_id = 'mc-83j29'
      @lists = double(
        static_segment_add: { 'id' => @mc_segment_id },
        member_info: { 'success_count' => 0 },
        subscribe: true,
        static_segment_members_add: true
      )
      mailchimp = double(lists: @lists)
      allow(Mailchimp::API).to receive(:new).and_return(mailchimp)
    end

    subject do
      Outreach::CreateOrganizationSubscriptionInMailchimp.call(@org_subscription)
    end

    it "creates mailchimp_segment_id for Organization" do
      expect{ subject }.to change{
        @organization.reload.mc_segment_id
      }.to @mc_segment_id
    end

    it "ensures user is on Mailchimp master list" do
      expect(@lists).to receive(:member_info).with(
        @master_list_id,
        [{ email: @user.email }]
      )
      subject
    end

    it "calls to subscribe user to Mailchimp list" do
      expect(@lists).to receive(:subscribe).with(
        @master_list_id,
        { email: @user.email },
        nil,
        "html",
        false
      )
      subject
    end

    context "when Organization has mc_segment_id" do
      before do
        @organization.update_attribute(:mc_segment_id, @mc_segment_id)
      end

      it "does not add segment to master Mailchimp list" do
        expect(@lists).not_to receive(:static_segment_add)
        subject
      end
    end

    context "when organization_subscription is persisted and deleted" do
      before do
        @org_subscription.deleted_at = Time.current
        @org_subscription.save
      end

      it "updates deleted_at to nil" do
        expect{ subject }.to change{
          @org_subscription.deleted_at
        }.to nil
      end
    end
  end
end