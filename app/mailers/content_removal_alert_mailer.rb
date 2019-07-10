# frozen_string_literal: true

class ContentRemovalAlertMailer < ApplicationMailer
  def content_removal_alert(content)
    @content = content
    @content_type = @content.channel_type == 'Comment' ? 'comment' : 'post'
    mail(to: @content.created_by.email,
         from: 'HereCast <notifications@herecast.us>',
         subject: "Your #{@content_type} has been removed from HereCast")
  end
end
