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
      if content.content_type == :news && ENV['PRODUCTION_MESSAGING_ENABLED'] == "true"
        IntercomService.send_published_content_event(content)
      end
    end
  end
end