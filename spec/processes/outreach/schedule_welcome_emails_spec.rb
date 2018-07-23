require 'spec_helper'

RSpec.describe Outreach::ScheduleWelcomeEmails do

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

    subject { Outreach::ScheduleWelcomeEmails.call(@user) }

    it "schedules SIX successive welcome campaigns" do
      Outreach::ScheduleWelcomeEmails.new(@user).send(:ordered_steps).each do |step|
        expect(@campaigns_array).to receive(:create).with(
          'regular',
          standard_opts.merge({
            subject: Rails.configuration.subtext.email_outreach.send(step).subject,
            template_id: Rails.configuration.subtext.email_outreach.send(step).template_id
          }),
          { sections: {} },
          { saved_segment_id: @user.mc_segment_id }
        )
      end
      expect(@campaigns_array).to receive(:schedule).exactly(6).times
      subject
    end
  end
end