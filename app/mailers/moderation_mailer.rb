# frozen_string_literal: true

class ModerationMailer < ActionMailer::Base
  BUSINESS_MODERATION_EMAIL_RECIPIENT = Figaro.env.business_moderation_email? ? Figaro.env.business_moderation_email \
    : Rails.configuration.subtext.emails.moderation

  def send_moderation_flag(content, params, subject)
    @content = content
    @params = params
    @admin_uri = edit_content_url(@content.id)
    mail(from: Rails.configuration.subtext.emails.no_reply,
         to: Rails.configuration.subtext.emails.moderation,
         subject: subject,
         skip_premailer: true)
  end

  def send_moderation_flag_v2(content, flag_type, flagging_user)
    @content = content
    @flag_type = flag_type
    @flagger = flagging_user
    @admin_uri = edit_content_url(@content.id)

    subject = 'HereCast Flagged as ' + flag_type + ': ' + content.title

    mail(from: Rails.configuration.subtext.emails.no_reply,
         to: Rails.configuration.subtext.emails.moderation,
         subject: subject,
         skip_premailer: true)
  end

  def send_business_for_moderation(business_profile, user)
    @business_profile = business_profile
    @location = @business_profile.business_location
    @content = @business_profile.content
    @categories = @business_profile.business_categories
    @user = user
    subject = 'New Business for Moderation'
    mail(from: Rails.configuration.subtext.emails.no_reply,
         to: BUSINESS_MODERATION_EMAIL_RECIPIENT,
         subject: subject)
  end
end
