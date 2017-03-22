class ModerationMailer < ActionMailer::Base

  BUSINESS_MODERATION_EMAIL_RECIPIENT = Figaro.env.business_moderation_email? ? Figaro.env.business_moderation_email \
    : Rails.configuration.subtext.emails.moderation


  def send_moderation_flag(content, params, subject)
    @content = content
    @params = params
    if @content.channel_type == 'Event'
      @admin_uri = edit_event_url(@content.channel_id)
    elsif @content.channel_type == 'MarketPost'
      @admin_uri = edit_market_post_url(@content.channel_id)
    else
      @admin_uri = edit_content_url(@content.id)
    end
    mail(from: Rails.configuration.subtext.emails.no_reply,
         to: Rails.configuration.subtext.emails.moderation,
         subject: subject,
         skip_premailer: true)
  end

  def send_moderation_flag_v2(content, flag_type, flagging_user)
    @content = content
    @flag_type = flag_type
    @flagger = flagging_user

    if @content.channel_type == 'Event'
      @admin_uri = edit_event_url(@content.channel_id)
    elsif @content.channel_type == 'MarketPost'
      @admin_uri = edit_market_post_url(@content.channel_id)
    else
      @admin_uri = edit_content_url(@content.id)
    end

    subject = 'dailyUV Flagged as ' + flag_type + ': ' + content.title

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
