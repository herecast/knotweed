class AssignFirstServedAtToNewContent

  def self.call(*args)
    self.new(*args).call
  end

  def initialize(content_ids:, current_time:)
    @contents = Content.where(id: content_ids)
    @current_time = Time.parse(current_time)
  end

  def call
    @contents.where(first_served_at: nil).each do |content|
      content.update_attribute(:first_served_at, @current_time)
      if ENV['PRODUCTION_MESSAGING_ENABLED'] == "true"
        if content.content_type == :news
          IntercomService.send_published_content_event(content)
          SlackService.send_published_content_notification(content)
        end
        if content.created_by&.has_role?(:promoter)
          IntercomService.send_published_storyteller_content_alert(content)
          SlackService.send_storyteller_post_notification(content)
        end
      end
    end
  end
end