module Outreach
  class SendOrganizationPostNotification
    include ContentsHelper
    include EmailTemplateHelper
    include MailchimpAPI

    ERB_NEWS_TEMPLATE_PATH = "#{Rails.root}/app/views/subscriptions_notifications/notification.html.erb"
    ERB_FEATURE_NOTIFICATION_TEMPLATE_PATH = "#{Rails.root}/app/views/subscriptions_notifications/feature_notification.html.erb"

    def self.call(*args)
      self.new(*args).call
    end

    def initialize(content)
      @content           = content
      @organization      = content.organization
      @title             = content.title
      @post_url          = "#{@organization_url}/#{content.id}"
      @profile_image_url = @organization.profile_image_url
    end

    def call
      raise_error_if_organization_has_no_active_subscribers
      response = create_campaign
      schedule_campaign(response)
      @content.update_attribute(:mc_campaign_id, response['id'])
    end

    private

      def raise_error_if_organization_has_no_active_subscribers
        if @organization.active_subscriber_count == 0
          raise "Organization has no subscribers"
        end
      end

      def campaign_subject
        if @organization.feature_notification_org?
          'New DailyUV Features!'
        else
          "#{@content.location.pretty_name} | #{@content.title}"
        end
      end

      def create_campaign
        mailchimp_connection.campaigns.create('regular', {
            list_id: mailchimp_master_list_id,
            subject: campaign_subject,
            from_email: 'dailyUV@subtext.org',
            from_name: @organization.name
          }, {
            html: ERB.new(File.read(html_path)).result(binding)
          },
          saved_segment_id: @organization.mc_segment_id
        )
      end

      def html_path
        if @organization.feature_notification_org?
          ERB_FEATURE_NOTIFICATION_TEMPLATE_PATH
        else
          ERB_NEWS_TEMPLATE_PATH
        end
      end

      def schedule_campaign(response)
        mailchimp_connection.campaigns.schedule(
          response['id'],
          5.minutes.from_now.utc.to_s.sub(' UTC', '')
        )
      end

  end
end