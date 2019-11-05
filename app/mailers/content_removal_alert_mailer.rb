# frozen_string_literal: true

class ContentRemovalAlertMailer < ApplicationMailer
  def content_removal_alert(content)
    @content = content
    if content.is_a? Comment
      @content_type = 'comment'
    else
      @content_type = 'post'
    end
    mail(to: @content.created_by.email,
         from: 'HereCast <notifications@herecast.us>',
         subject: "Your #{@content_type} has been removed from HereCast")
  end
end
