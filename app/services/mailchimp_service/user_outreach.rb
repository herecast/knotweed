module MailchimpService
  module UserOutreach
    extend self

    DEFAULT_FROM_EMAIL = 'jennifer.sensenich@subtext.org'
    DEFAULT_FROM_NAME = 'Jennifer from DailyUV'

    def create_campaign(user:, subject:, template_id:)
      new_mailchimp_connection.campaigns.create('regular', {
        list_id: Rails.configuration.subtext.email_outreach.new_user_list_id,
        subject: subject,
        from_email: DEFAULT_FROM_EMAIL,
        from_name: DEFAULT_FROM_NAME,
        to_name: user.name,
        template_id: template_id
      }, {
        sections: {}
      }, {
        saved_segment_id: user.mc_segment_id
      })
    end

    def schedule_campaign(campaign_id)
      new_mailchimp_connection.campaigns.schedule(campaign_id,
        mailchimp_safe_schedule_time.utc.to_s.sub(' UTC', '')
      )
    end

    private

      def new_mailchimp_connection
        Mailchimp::API.new(Figaro.env.mailchimp_api_key)
      end

      def mailchimp_safe_schedule_time
        Time.at(((Time.current - 1.second).to_f / 15.minutes.to_i).floor * 15.minutes.to_i) + 15.minutes
      end

  end
end