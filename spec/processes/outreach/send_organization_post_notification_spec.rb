# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Outreach::SendOrganizationPostNotification do
  describe '::call' do
    before do
      @mc_segment_id = 'mc-nj345k'
      @caster = FactoryGirl.create :caster, mc_followers_segment_id: @mc_segment_id
      @organization = FactoryGirl.create :organization, user_id: @caster.id
      @content = FactoryGirl.create :content, :news, created_by: @caster
      @mc_campaign_id = 'mc-243nk'
      @campaigns = double(
        create: { 'id' => @mc_campaign_id },
        schedule: true
      )
      mailchimp = double(campaigns: @campaigns)
      allow(Mailchimp::API).to receive(:new).and_return(mailchimp)
      env = double(
        mailchimp_api_key: 'dummy',
        default_consumer_host: 'localhost'
      )
      allow(Figaro).to receive(:env).and_return(env)
    end

    subject do
      Outreach::SendOrganizationPostNotification.call(@content)
    end

    context 'when Caster has no subscribers' do
      it 'raises error' do
        expect { subject }.to raise_error 'Caster has no subscribers'
      end
    end

    context 'when Caster has subscribers' do
      before do
        FactoryGirl.create :organization_subscription,
                           caster_id: @caster.id
      end

      it 'calls to Mailchimp to create campaign' do
        expect(@campaigns).to receive(:create).with(
          'regular', {
            list_id: MailchimpAPI.config.master_list_id,
            subject: an_instance_of(String),
            from_email: 'noreply@herecast.us',
            from_name: 'HereCast'
          }, {
            html: an_instance_of(String)
          },
          saved_segment_id: @mc_segment_id
        )
        subject
      end

      it 'schedules Mailchimp campaign' do
        expect(@campaigns).to receive(:schedule).with(
          @mc_campaign_id,
          an_instance_of(String)
        )
        subject
      end

      it 'updates Content model with Mailchimp campaign id' do
        expect { subject }.to change {
          @content.reload.mc_campaign_id
        }.to @mc_campaign_id
      end

      context 'when subject line is too long' do
        before do
          @handle = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation'
          caster = FactoryGirl.create :caster, handle: @handle
          @content = FactoryGirl.create :content,
                                        created_by_id: caster.id,
                                        location: FactoryGirl.create(:location)
          @max = Outreach::SendOrganizationPostNotification::MAX_SUBJECT_LENGTH
          @subj = Outreach::SendOrganizationPostNotification.new(
            @content
          ).send(:campaign_subject)
        end

        it 'expects test title to be too long' do
          expect(@subj.length).to be > @max
        end

        it 'truncates title' do
          formatted_subj = Outreach::SendOrganizationPostNotification.new(
            @content
          ).send(:formatted_subject, @subj)
          expect(formatted_subj.length).to be <= @max
        end
      end
    end
  end
end
