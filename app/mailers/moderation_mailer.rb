class ModerationMailer < ActionMailer::Base

  MODERATION_EMAIL_RECIPIENT = 'flags@subtext.org'
  MODERATION_EMAIL_SENDER = 'noreply@subtext.org'


  def send_moderation_flag(content, params, subject)
    @content = content
    @params = params
    @admin_uri = params[:adminURL] + get_admin_uri(params[:baseURI])
    uri = params[:baseURI]
    mail(from: "flags@dailyuv.com",
         to: MODERATION_EMAIL_RECIPIENT,
         subject: subject)
  end

  private

  MPFRAG = 'market_posts'
  EVFRAG = 'events'
  CONTENTFRAG = 'contents'

  def get_admin_uri(baseURI)

    mpstart = baseURI.index(MPFRAG)
    evstart = baseURI.index(EVFRAG)
    contentstart = baseURI.index(CONTENTFRAG)
    if mpstart
      admin_url = edit_market_post_path(baseURI[mpstart+MPFRAG.length+1..-1])
    elsif evstart
      url_end = baseURI[evstart+EVFRAG.length+1..-1]
      event_id = url_end[0..url_end.index('/')-1]
      admin_url = edit_event_path(event_id)
    else
      admin_url = edit_content_path(baseURI[contentstart+CONTENTFRAG.length+1..-1])
    end

  end
end