class ReversePublisher < ActionMailer::Base

  def send_content_to_reverse_publishing_email(content, publication)
    headers['In-Reply-To'] = content.parent.try(:guid)
    @body = content.raw_content
    mail(from: content.authoremail,
         to: publication.reverse_publish_email,
         subject: content.title,
         cc: content.authoremail)
  end

end
