# frozen_string_literal: true

# alert content owner when comments are made on content
class CommentAlert
  def self.call(comment)
    parent_content = comment.content
    if comment.is_a?(Comment) &&
        !parent_content.nil? &&
        parent_content.ok_to_send_alert? &&
        parent_content.created_by != comment.created_by
      CommentAlertMailer.alert_parent_content_owner(comment, parent_content).deliver_later
    end
  end
end
