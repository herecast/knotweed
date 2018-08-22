module Outreach
  class ScheduleBloggerEmails

    def self.call(*args)
      self.new(*args).call
    end

    def initialize(user:, organization:)
      @user         = user
      @organization = organization
    end

    def call
      blogger_welcome
      blogger_reminder
    end

    private

      def blogger_welcome
        response = create_campaign('blogger_welcome')
        schedule_campaign(response, Time.current)
      end

      def blogger_reminder
        response = create_campaign('blogger_reminder')
        schedule_campaign(response, Time.current + 2.weeks)
        @organization.update_attribute(:reminder_campaign_id, response['id'])
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
          timing: timing
        )
      end

  end
end
