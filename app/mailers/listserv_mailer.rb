# frozen_string_literal: true

class ListservMailer < ActionMailer::Base
  default from: Rails.configuration.subtext.emails.listserv
  layout 'listserv_mailer'

  add_template_helper EmailTemplateHelper
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
end
