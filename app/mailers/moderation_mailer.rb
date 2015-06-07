class ModerationMailer < ActionMailer::Base

  MODERATION_EMAIL_RECIPIENT = 'ngottlieb@gmail.com'
  MODERATION_EMAIL_SENDER = 'noreply@subtext.org'


  def send_moderation_flag(content, params, subject)
    @content = content
    @params = params
    if @content.channel_type == Event
      @admin_uri = edit_event_url(@content.channel_id)
    elsif @content.channel_type == MarketPost
      @admin_uri = edit_market_post_url(@content.channel_id)
    else
      @admin_uri = edit_content_url(@content.id)
    end
    mail(from: MODERATION_EMAIL_SENDER,
         to: MODERATION_EMAIL_RECIPIENT,
         subject: subject)
  end

  def send_moderation_flag_v2(content, flag_type, flagging_user)
    @content = content
    @flag_type = flag_type
    @flagger = flagging_user

    if @content.channel_type == Event
      @admin_uri = edit_event_url(@content.channel_id)
    elsif @content.channel_type == MarketPost
      @admin_uri = edit_market_post_url(@content.channel_id)
    else
      @admin_uri = edit_content_url(@content.id)
    end

    subject = 'dailyUV Flagged as ' + flag_type + ': ' + content.title

    mail(from: MODERATION_EMAIL_SENDER,
         to: MODERATION_EMAIL_RECIPIENT,
         subject: subject)
  end

end
