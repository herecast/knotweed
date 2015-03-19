class ReversePublisher < ActionMailer::Base
  helper :events

  def send_content_to_reverse_publishing_email(content, publication)
    headers['In-Reply-To'] = content.parent.try(:guid)
    @body = content.raw_content
    mail(from: '"'+content.authors+'" <'+content.authoremail+'>',
         to: publication.reverse_publish_email,
         subject: content.title)
  end

  def send_copy_to_sender_from_dailyuv(content, publication)
    headers['In-Reply-To'] = content.parent.try(:guid)
    @body = content.raw_content
    mail(from: "noreply@dailyuv.com",
         to: content.authoremail,
         subject: content.title)
  end

  def send_event_to_listserv(event, publication, consumer_app=nil)
    # custom header so that we can identify events
    # that already exist in our system as "curated" when they come back through
    headers['X-Original-Content-Id'] = event.content.id
    @event = event
    @venue = BusinessLocation.find(@event.venue_id)
    if consumer_app.present?
      @base_uri = consumer_app.uri
    end
    mail(from: '"'+event.authors+'" <'+event.authoremail+'>',
         to: publication.reverse_publish_email,
         subject: event.title)
  end

  def send_market_post_to_listserv(market_post, publication, consumer_app=nil)
    headers['X-Original-Content-Id'] = market_post.content.id
    @market_post = market_post
    if consumer_app.present?
      @base_uri = consumer_app.uri
    end
    mail(from: '"'+market_post.content.authors+'" <'+market_post.content.authoremail+'>',
         to: publication.reverse_publish_email,
         subject: market_post.content.title)
  end

end
