class AdMailer < ActionMailer::Base
  default from: Rails.configuration.subtext.emails.notifications

  def event_adveritising_request(user, event)
    @user = user
    @event = event
    mail(to: Rails.configuration.subtext.emails.advertising, subject: "#{@user.email} wants to advertise an event")
  end
end
