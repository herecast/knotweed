class ModerationMailer < ActionMailer::Base

  MODERATION_EMAIL_RECIPIENT = 'rich.cohen@subtext.org'

  def send_moderation_flag(content, params, subject)
    @content = content
    @params = params
    mail(from: "flags@dailyuv.com",
         to: MODERATION_EMAIL_RECIPIENT,
         subject: subject)
  end

end