require 'spec_helper'

RSpec.describe CreateUserOutreachMailchimpCampaign do

  describe "::call" do

    before do
      @user = FactoryGirl.create :user,
        mc_segment_id: '43nj2k4'
      @campaign_id = '43n2hjb4'
      @campaigns_array = double(
        create: { 'id' => @campaign_id },
        schedule: true
      )
      mailchimp = double(campaigns: @campaigns_array)
      allow(Mailchimp::API).to receive(:new)
        .and_return(mailchimp)
    end

    let(:standard_opts) do
      {
        list_id: Rails.configuration.subtext.email_outreach.new_user_list_id,
        from_email: MailchimpService::UserOutreach::DEFAULT_FROM_EMAIL,
        from_name: MailchimpService::UserOutreach::DEFAULT_FROM_NAME,
        to_name: @user.name
      }
    end

    context 'when User creates first Market Post' do
      subject { CreateUserOutreachMailchimpCampaign.call(type: 'market_post', user: @user) }

      it "calls to Mailchimp to create campaign" do
        expect(@campaigns_array).to receive(:create).with(
          'regular',
          standard_opts.merge({
            subject: Rails.configuration.subtext.email_outreach.initial_market_post.subject,
            template_id: Rails.configuration.subtext.email_outreach.initial_market_post.template_id
          }),
          { sections: {} },
          { saved_segment_id: @user.mc_segment_id }
        )
        subject
      end

      it "calls Mailchimp to schedule campaign" do
        expect(@campaigns_array).to receive(:schedule).with(
          @campaign_id,
          any_args
        )
        subject
      end
    end

    context 'when User creates first Event' do
      subject { CreateUserOutreachMailchimpCampaign.call(type: 'event', user: @user) }

      it "calls to Mailchimp to create campaign" do
        expect(@campaigns_array).to receive(:create).with(
          'regular',
          standard_opts.merge({
            subject: Rails.configuration.subtext.email_outreach.initial_event_post.subject,
            template_id: Rails.configuration.subtext.email_outreach.initial_event_post.template_id
          }),
          { sections: {} },
          { saved_segment_id: @user.mc_segment_id }
        )
        subject
      end

      it "calls Mailchimp to schedule campaign" do
        expect(@campaigns_array).to receive(:schedule).with(
          @campaign_id,
          any_args
        )
        subject
      end
    end
  end
end