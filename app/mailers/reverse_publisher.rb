class ReversePublisher < ActionMailer::Base
  helper :events

  def send_content_to_reverse_publishing_email(content, listserv, consumer_app=nil)
    # these are the same regardless of channel
    to = listserv.reverse_publish_email
    from = "\"#{content.authors}\" <#{content.authoremail}>"
    subject = content.title
    if content.channel.nil? # if unchannelized
      headers['In-Reply-To'] = content.parent.try(:guid)
      @body = content.raw_content
      template_name = 'content'
    else # if channelized
      if consumer_app.present?
        @base_uri = consumer_app.uri
      end
      # custom header so that we can identify events
      # that already exist in our system as "curated" when they come back through
      headers['X-Original-Content-Id'] = content.id
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
    @body = content.raw_content
    mail(from: "noreply@dailyuv.com",
         to: content.authoremail,
         subject: content.title)
  end

end
