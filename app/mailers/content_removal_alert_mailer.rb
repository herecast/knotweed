class ContentRemovalAlertMailer < ApplicationMailer
  def content_removal_alert(content)
    @content = content
    @content_type = @content.channel_type == 'Comment' ? 'comment' : 'post'
    mail(to: @content.created_by.email,
         from: "DailyUV <notifications@dailyuv.com>",
         subject: "Your #{@content_type} has been removed from DailyUV")
  end
end
