# frozen_string_literal: true

class ManageContentOnFirstServe
  def self.call(*args)
    new(*args).call
  end

  def initialize(content_ids:, current_time:)
    @contents = Content.where(id: content_ids)
    @current_time = Time.parse(current_time)
  end

  def call
    @contents = @contents.where(first_served_at: nil)
                         .where.not(pubdate: nil)
                         .where('pubdate < ?', Time.current)

    @contents.each do |content|
      content.with_lock do
        # extra check to avoid race condition
        if content.first_served_at.nil?
          content.update_attribute(:first_served_at, @current_time)
          conditionally_schedule_outreach(content)
          conditionally_schedule_notification(content)
          if Figaro.env.production_messaging_enabled == 'true'
            FacebookService.rescrape_url(content)
            if content.content_type == :news
              IntercomService.send_published_content_event(content)
              SlackService.send_published_content_notification(content)
            end
          end
        end
      end
    end
  end

  private

  def conditionally_schedule_outreach(content)
    organization = content.organization
    if organization.org_type == 'Blog'
      conditionally_cancel_reminder_campaign(organization)
      ordered_ids = organization.contents.order(pubdate: :asc).pluck(:id)

      # on Org create, we attach a dummy content,
      # hence bumping these indexes forward by one
      begin
        if ordered_ids.index(content.id) == 1
          Outreach::ScheduleBloggerEmails.call(
            action: 'first_blogger_post',
            user: content.created_by
          )
        elsif ordered_ids.index(content.id) == 3
          Outreach::ScheduleBloggerEmails.call(
            action: 'third_blogger_post',
            user: content.created_by
          )
        end
      rescue Mailchimp::Error => e
        SlackService.send_new_blogger_error_alert(
          error: e,
          user: content.created_by,
          organization: organization
        )
      end
    end

    def conditionally_schedule_notification(content)
      if content.should_notify_subscribers?
        begin
          BackgroundJob.perform_later('Outreach::SendOrganizationPostNotification',
            'call',
            content
          )
        rescue
        end
      end
    end
  end

  def conditionally_cancel_reminder_campaign(organization)
    if organization.reminder_campaign_id.present?
      unless MailchimpService::UserOutreach.get_campaign_status(organization.reminder_campaign_id) == 'sent'
        MailchimpService::UserOutreach.delete_campaign(organization.reminder_campaign_id)
      end
      organization.update_attribute(:reminder_campaign_id, nil)
    end
  end
end
