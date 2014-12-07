class ReversePublisher < ActionMailer::Base

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

end
