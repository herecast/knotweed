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

    def create_list(name)
      post('/lists', body: default_list_data.merge(name: name).to_json)
    end

    def subscribe_user_to_list(list_id:, user:)
      new_mailchimp_connection.lists.subscribe(list_id, {
        email: user.email
      }, nil, 'html', false)
    end

    def delete_list(list_id)
      delete("/lists/#{list_id}")
    end

    def create_test_campaign(list_id:, digest:)
      post('/campaigns', {
        body: serialized_digest(list_id, digest).to_json
      })
    end

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
      }, {
        saved_segment_id: user.mc_segment_id
      })
    end

    def schedule_campaign(campaign_id, timing: Time.current)
      new_mailchimp_connection.campaigns.schedule(campaign_id,
        mailchimp_safe_schedule_time(timing).utc.to_s.sub(' UTC', '')
      )
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

      def default_list_data
        {
          permission_reminder: 'You\'re receiving this email because you are a tester',
          email_type_option: true,
          contact: {
            company: 'Subtext Media',
            address1: "15 RailRoad Row",
            city: "White River Junction",
            state: "VT",
            zip: "03770",
            country: 'USA'
          },
          campaign_defaults: {
            from_name: "DUV Test",
            from_email: "it@subtext.org",
            subject: "Test digest",
            language: "en"
          }
        }
      end

      def serialized_digest(list_id, digest)
        {
          type: 'regular',
          recipients: {
            list_id: list_id,
          },
          settings: {
            title: digest.title,
            subject_line: digest.subject,
            from_name: digest.from_name,
            reply_to: digest.reply_to
          }
        }
      end

  end
end