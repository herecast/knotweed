# frozen_string_literal: true

module Outreach
  class ScheduleBloggerEmails
    def self.call(*args)
      new(*args).call
    end

    def initialize(action:, user:, organization: nil)
      @action       = action
      @user         = user
      @organization = organization
    end

    def call
      conditionally_add_blogger_to_new_users_list
      if @action == 'blogger_welcome_and_reminder'
        create_and_schedule_campaign('blogger_welcome')
        response = create_and_schedule_campaign('blogger_reminder', Time.current + 2.weeks)
        @organization.update_attribute(:reminder_campaign_id, response['id'])
      else
        create_and_schedule_campaign(@action)
      end
    end

    private

    def conditionally_add_blogger_to_new_users_list
      unless @user.mc_segment_id.present?
        CreateMailchimpSegmentForNewUser.call(@user,
                                              organization: @organization)
      end
    end

    def create_and_schedule_campaign(step, send_time = Time.current)
      response = create_campaign(step)
      schedule_campaign(response, send_time)
      response
    end

    def email_config
      Rails.configuration.subtext.email_outreach
    end

    def create_campaign(step)
      MailchimpService::UserOutreach.create_campaign(
        user: @user,
        subject: email_config.send(step).subject,
        template_id: email_config.send(step).template_id,
        from_email: 'aileen.lem@subtext.org',
        from_name: 'Aileen from DailyUV'
      )
    end

    def schedule_campaign(response, timing)
      MailchimpService::UserOutreach.schedule_campaign(response['id'],
                                                       timing: timing)
    end
  end
end
