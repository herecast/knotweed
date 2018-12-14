class CommentAlertPreview < ActionMailer::Preview
  def alert_parent_content_owner
    comments = Comment.last(2)
    comments.map { |c| c.update_attribute(:created_by, User.last) }
    CommentAlertMailer.alert_parent_content_owner(comments.first, comments.last)
  end
end
