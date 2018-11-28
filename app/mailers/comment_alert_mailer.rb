class CommentAlertMailer < ApplicationMailer
  add_template_helper ContentsHelper
  add_template_helper EmailTemplateHelper

  layout 'comment_alert_email'

  def alert_parent_content_owner(comment, parent_content, comment_hidden=false)
    @comment = comment
    @parent_content = parent_content
    @comment_owner = @comment.created_by
    @comment_hidden = comment_hidden
    mail(to: @parent_content.created_by.email,
         from: "DailyUV <notifications@dailyuv.com>",
         subject: comment_hidden ? removed_subject : created_subject)
  end

  private

    def removed_subject
      "A comment has been removed from your post on DailyUV"
    end

    def created_subject
      "#{@comment_owner.name} just commented on your post on DailyUV"
    end

end
