class AssignFirstServedAtToNewContent

  def self.call(*args)
    self.new(*args).call
  end

  def initialize(content_ids:, current_time:)
    @contents = Content.where(id: content_ids)
    @current_time = Time.parse(current_time)
  end

  def call
    @contents.where(first_served_at: nil).update_all(first_served_at: @current_time)
  end
end