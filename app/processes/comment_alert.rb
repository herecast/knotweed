#alert content owner when comments are made on content
class CommentAlert

  def self.call(content)
    parent_content = content.parent
    unless parent_content.nil? || parent_content.organization.name == "Listserv"
      parent_content_owner = parent_content.created_by
      if content.content_type == :comment && parent_content_owner.receive_comment_alerts
        unless parent_content_owner == content.created_by
          CommentAlertMailer.alert_parent_content_owner(content, content.parent).deliver_later
        end
      end
    end
  end
end
