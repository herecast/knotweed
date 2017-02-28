class AdMailer < ActionMailer::Base
  default from: Rails.configuration.subtext.emails.notifications

  def event_advertising_user_contact(user)
    mail to: user.email, subject: "Boosting your event on DailyUV"
  end

  def event_adveritising_request(user, event)
    @user = user
    @event = event
    mail(to: Rails.configuration.subtext.emails.advertising, subject: "#{@user.email} wants to advertise an event")
  end

  def coupon_request(email, promotion_coupon)
    @promotion_coupon = promotion_coupon
    title = promotion_coupon.promotion.content.try(:title)
    mail to: email, subject: "Coupon for #{title}"
  end
end
