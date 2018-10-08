class CommentAlertMailer < ApplicationMailer
  add_template_helper ContentsHelper
  add_template_helper EmailTemplateHelper

  layout 'comment_alert_email'

  def alert_parent_content_owner(comment, parent_content)
    @comment = comment
    @parent_content = parent_content
    comment_owner = @comment.created_by
    mail(to: @parent_content.created_by.email,
         from: "#{comment_owner.name} via DailyUV <notifications@dailyuv.com>",
         subject: "#{comment_owner.name} commented on your post '#{@parent_content.title}'")
  end

end
