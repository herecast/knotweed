class ReversePublisher < ActionMailer::Base
  helper :events

  def send_content_to_reverse_publishing_email(content, listserv, consumer_app=nil)
    # these are the same regardless of channel
    to = listserv.reverse_publish_email
    from = "\"#{content.authors}\" <#{content.authoremail}>"
    subject = content.title
    @body = content.raw_content_for_text_email
    # custom header so that we can identify any content that already exists in our system
    headers['X-Original-Content-Id'] = content.id
    if consumer_app.present?
      @base_uri = consumer_app.uri
    end
    if content.channel.nil? or content.channel.is_a? Comment # if unchannelized or comment
      headers['In-Reply-To'] = content.parent.try(:guid)
      template_name = 'content'
      @content = content
    else # if channelized
      if content.channel.is_a? Event
        @event = content.channel
        @venue = @event.venue
        template_name = 'event'
      elsif content.channel.is_a? MarketPost
        @market_post = content.channel
        template_name = 'market_post'
      end
    end
    mail(from: from, to: to, subject: subject, template_name: template_name)
  end

  def send_copy_to_sender_from_dailyuv(content, publication)
    headers['In-Reply-To'] = content.parent.try(:guid)
    @body = content.raw_content_for_text_email
    mail(from: "noreply@dailyuv.com",
         to: content.authoremail,
         subject: content.title)
  end

end
