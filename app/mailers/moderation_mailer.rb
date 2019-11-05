# frozen_string_literal: true

class ModerationMailer < ActionMailer::Base
  BUSINESS_MODERATION_EMAIL_RECIPIENT = Figaro.env.business_moderation_email? ? Figaro.env.business_moderation_email \
    : Rails.configuration.subtext.emails.moderation

  def send_moderation_flag_v2(content, flag_type, flagging_user)
    @content = content
    if content.is_a? Content
      @author = "#{content.authors} #{content.authoremail}"
      @title = content.title
      @admin_uri = edit_content_url(@content.id)
    elsif content.is_a? Comment
      @author = "#{content.created_by.try(:name)} #{content.created_by.email}"
      @title = "comment on #{content.content.title}"
      # NOTE: there is no edit URI for comments...
    end
    @flag_type = flag_type
    @flagger = flagging_user

    subject = 'HereCast Flagged as ' + flag_type + ': ' + @title

    mail(from: Rails.configuration.subtext.emails.no_reply,
         to: Rails.configuration.subtext.emails.moderation,
         subject: subject,
         skip_premailer: true)
  end
end
