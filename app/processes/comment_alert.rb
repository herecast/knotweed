# frozen_string_literal: true

# alert content owner when comments are made on content
class CommentAlert
  def self.call(content)
    parent_content = content.parent
    unless parent_content.nil? || parent_content.organization.name == 'Listserv'
      if content.content_type == 'comment' && parent_content.ok_to_send_alert?
        unless parent_content.created_by == content.created_by
          CommentAlertMailer.alert_parent_content_owner(content, content.parent).deliver_later
        end
      end
    end
  end
end
