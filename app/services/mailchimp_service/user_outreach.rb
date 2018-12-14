# frozen_string_literal: true

module MailchimpService
  module UserOutreach
    extend self

    include HTTParty

    format     :json
    base_uri   "https://#{Figaro.env.mailchimp_api_host}/3.0"
    basic_auth 'user', Figaro.env.mailchimp_api_key.to_s
    headers    'Content-Type' => 'application/json',
               'Accept' => 'application/json'

    DEFAULT_FROM_EMAIL = 'jennifer.sensenich@subtext.org'
    DEFAULT_FROM_NAME = 'Jennifer from DailyUV'

    def create_campaign(user:, subject:, template_id:, from_email: DEFAULT_FROM_EMAIL, from_name: DEFAULT_FROM_NAME)
      new_mailchimp_connection.campaigns.create('regular', {
                                                  list_id: Rails.configuration.subtext.email_outreach.new_user_list_id,
                                                  subject: subject,
                                                  from_email: from_email,
                                                  from_name: from_name,
                                                  to_name: user.name,
                                                  template_id: template_id
                                                }, {
                                                  sections: {}
                                                },
                                                saved_segment_id: user.mc_segment_id)
    end

    def schedule_campaign(campaign_id, timing: Time.current)
      new_mailchimp_connection.campaigns.schedule(campaign_id,
                                                  mailchimp_safe_schedule_time(timing).utc.to_s.sub(' UTC', ''))
    end

    def get_campaign_status(campaign_id)
      get("/campaigns/#{campaign_id}")
    end

    def delete_campaign(campaign_id)
      new_mailchimp_connection.campaigns.delete(campaign_id)
    end

    private

    def new_mailchimp_connection
      Mailchimp::API.new(Figaro.env.mailchimp_api_key)
    end

    def mailchimp_safe_schedule_time(timing)
      Time.at(((timing - 1.second).to_f / 15.minutes.to_i).floor * 15.minutes.to_i) + 15.minutes
    end
  end
end
