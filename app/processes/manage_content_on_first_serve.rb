class ManageContentOnFirstServe

  def self.call(*args)
    self.new(*args).call
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
      content.update_attribute(:first_served_at, @current_time)
      conditionally_schedule_outreach(content)
      if Figaro.env.production_messaging_enabled == "true"
        FacebookService.rescrape_url(content)
        if content.content_type == :news
          IntercomService.send_published_content_event(content)
          SlackService.send_published_content_notification(content)
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
        if ordered_ids.index(content.id) == 1
          Outreach::CreateUserHookCampaign.call(
            user: content.created_by,
            action: 'first_blogger_post'
          )
        elsif ordered_ids.index(content.id) == 3
          Outreach::CreateUserHookCampaign.call(
            user: content.created_by,
            action: 'third_blogger_post'
          )
        end
      end
    end

    def conditionally_cancel_reminder_campaign(organization)
      if organization.reminder_campaign_id.present?
        unless MailchimpService::UserOutreach.get_campaign_status(organization.reminder_campaign_id) == "sent"
          MailchimpService::UserOutreach.delete_campaign(organization.reminder_campaign_id)
          organization.update_attribute(:reminder_campaign_id, nil)
        end
      end
    end

end