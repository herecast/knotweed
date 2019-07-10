# frozen_string_literal: true

module Outreach
  class SendOrganizationPostNotification
    include ContentsHelper
    include EmailTemplateHelper
    include MailchimpAPI

    ERB_NEWS_TEMPLATE_PATH = "#{Rails.root}/app/views/subscriptions_notifications/notification.html.erb"
    ERB_FEATURE_NOTIFICATION_TEMPLATE_PATH = "#{Rails.root}/app/views/subscriptions_notifications/feature_notification.html.erb"
    MAX_SUBJECT_LENGTH = 149

    def self.call(*args)
      new(*args).call
    end

    def initialize(content)
      @content           = content
      @organization      = content.organization
      @title             = content.title
      @post_url          = "#{@organization.profile_link}/#{content.id}"
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
        raise 'Organization has no subscribers'
      end
    end

    def campaign_subject
      if @organization.feature_notification_org?
        'New HereCast Features!'
      else
        "#{@content.location.pretty_name} | #{@organization.name}"
      end
    end

    def create_campaign
      mailchimp_connection.campaigns.create('regular', {
                                              list_id: mailchimp_config.master_list_id,
                                              subject: formatted_subject(campaign_subject),
                                              from_email: 'noreply@herecast.us',
                                              from_name: 'HereCast'
                                            }, {
                                              html: ERB.new(File.read(html_path)).result(binding)
                                            },
                                            saved_segment_id: @organization.mc_segment_id)
    end

    def formatted_subject(subject)
      if subject.length > MAX_SUBJECT_LENGTH
        "#{subject.slice(0, (MAX_SUBJECT_LENGTH - 2)).split(' ')[0..-2].join(' ')}..."
      else
        subject
      end
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
