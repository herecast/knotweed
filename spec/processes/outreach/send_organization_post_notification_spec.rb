# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Outreach::SendOrganizationPostNotification do
  describe '::call' do
    before do
      @mc_segment_id = 'mc-nj345k'
      @organization = FactoryGirl.create :organization,
        mc_segment_id: @mc_segment_id
      @content = FactoryGirl.create :content, :news,
        organization_id: @organization.id
      @mc_campaign_id = 'mc-243nk'
      @campaigns = double(
        create: { 'id' => @mc_campaign_id },
        schedule: true
      )
      mailchimp = double(campaigns: @campaigns)
      allow(Mailchimp::API).to receive(:new).and_return(mailchimp)
      @list_id = 'list-id'
      env = double(
        mailchimp_master_list_id: @list_id,
        mailchimp_api_key: 'dummy',
        default_host: 'dummy',
        default_consumer_host: 'localhost'
      )
      allow(Figaro).to receive(:env).and_return(env)
    end

    subject do
      Outreach::SendOrganizationPostNotification.call(@content)
    end

    context "when Organization has no subscribers" do
      it "raises error" do
        expect{ subject }.to raise_error "Organization has no subscribers"
      end
    end

    context "when Organization has subscribers" do
      before do
        FactoryGirl.create :organization_subscription,
          organization_id: @organization.id
      end

      it "calls to Mailchimp to create campaign" do
        expect(@campaigns).to receive(:create).with(
          'regular', {
            list_id: @list_id,
            subject: an_instance_of(String),
            from_email: 'dailyUV@subtext.org',
            from_name: @organization.name
          }, {
            html: an_instance_of(String)
          },
          saved_segment_id: @mc_segment_id
        )
        subject
      end

      it "schedules Mailchimp campaign" do
        expect(@campaigns).to receive(:schedule).with(
          @mc_campaign_id,
          an_instance_of(String)
        )
        subject
      end

      it "updates Content model with Mailchimp campaign id" do
        expect{ subject }.to change{
          @content.reload.mc_campaign_id
        }.to @mc_campaign_id
      end
    end
  end
end