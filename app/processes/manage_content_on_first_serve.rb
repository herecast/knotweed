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
          conditionally_schedule_notification(content)
          if production_messaging_enabled?
            scrape_with_facebook(content)
            if content.content_type == 'news'
              IntercomService.send_published_content_event(content)
              SlackService.send_published_content_notification(content)
            end
          end
        end
      end
    end
  end

  private

  def production_messaging_enabled?
    Figaro.env.production_messaging_enabled == 'true'
  end

  def conditionally_schedule_notification(content)
    if content.should_notify_subscribers?
      begin
        BackgroundJob.perform_later('Outreach::SendOrganizationPostNotification',
                                    'call',
                                    content)
      rescue StandardError
      end
    end
  end

  def scrape_with_facebook(content)
    begin
      FacebookService.rescrape_url(content)
    rescue
    end
  end
end
