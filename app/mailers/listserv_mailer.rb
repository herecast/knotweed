class ListservMailer < ActionMailer::Base
  default from: Rails.configuration.subtext.emails.listserv
  layout 'listserv_mailer'

  add_template_helper ContentsHelper

  def subscription_confirmation(sub)
    @subscription = sub
    @listserv = sub.listserv
    @digest_send_time = sub.listserv.next_digest_send_time.in_time_zone(sub.listserv.timezone).strftime("%l:%M %p (%Z)")

    mail(to: @subscription.email, subject: 'Subscription Details')
  end

  def subscription_verification(sub)
    @subscription = sub
    @listserv = sub.listserv

    mail(to: @subscription.email, subject: 'Complete your Subscription')
  end

  def existing_subscription(sub)
    @subscription = sub
    @listserv = sub.listserv

    mail(to: @subscription.email, subject: 'Complete your Subscription')
  end

  def posting_confirmation(post, temp_password = nil)
    @post = post
    @subscription = post.subscription
    @listserv = post.listserv
    @content = post.content
    if temp_password.present?
      @temp_password = AESCrypt.decrypt(
        temp_password,
        "listserv_content/#{post.key}"
      )
    end

    if @post.content_id?
      template = "posting_confirmation"
    else
      template = "no_enhance_posting_confirmation"
    end

    mail(to: @post.sender_email, subject: "#{@post.subject} - Your post is live! View Details", template_name: template)
  end

  def posting_verification(post)
    @post = post
    @subscription = post.subscription
    @listserv = post.listserv

    mail(to: @post.sender_email, subject: "#{@post.subject} - CONFIRM TO PUBLISH")
  end
end
