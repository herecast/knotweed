class ApplicationMailer < ActionMailer::Base
  default from: Rails.configuration.subtext.emails.no_reply

  layout 'mailer'
end
