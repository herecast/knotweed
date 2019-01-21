# frozen_string_literal: true

class AdMailer < ActionMailer::Base
  default from: Rails.configuration.subtext.emails.notifications

  def event_advertising_user_contact(user)
    mail to: user.email, subject: 'Boosting your event on DailyUV'
  end

  def event_advertising_request(user, event)
    @user = user
    @event = event
    mail(to: Rails.configuration.subtext.emails.advertising, subject: "#{@user.email} wants to advertise an event")
  end

  def coupon_request(email, promotion_coupon)
    @promotion_coupon = promotion_coupon
    title = promotion_coupon.promotion.content.try(:title)
    mail to: email, subject: "Coupon for #{title}"
  end

  def ad_sunsetting(promotion_banner)
    @promotion_banner = promotion_banner
    mail(to: Rails.configuration.subtext.emails.sunsetting_ads, subject: "Promotion with id: #{@promotion_banner.promotion.id} ends tomorrow")
  end
end
