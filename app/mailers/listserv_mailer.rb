class ListservMailer < ActionMailer::Base
  default from: Rails.configuration.subtext.emails.listserv
  layout 'listserv_mailer'

  add_template_helper ContentsHelper
  add_template_helper FeaturesHelper

  def subscription_verification(sub)
    @subscription = sub
    @listserv = sub.listserv

    mail(to: @subscription.email, subject: 'COMPLETE YOUR SUBSCRIPTION')
  end

  def existing_subscription(sub)
    @subscription = sub
    @listserv = sub.listserv

    mail(to: @subscription.email, subject: 'Complete your Subscription')
  end

  def posting_verification(post)
    @post = post
    @subscription = post.subscription
    @listserv = post.listserv

    mail(to: @post.sender_email, subject: "#{@post.subject} - CONFIRM TO PUBLISH") do |format|
      format.html { render layout: 'publish_confirmation_mailer' }
      format.text
    end
  end

  def subscriber_blacklisted(sub)
    @subscription = sub
    @listserv = sub.listserv

    mail(to: @subscription.email, subject: "You've been blocked from posting to the #{@listserv.name}")
  end
end
