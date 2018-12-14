Mail.defaults do
  if Rails.env.test?
    delivery_method :test
  elsif ActionMailer::Base.delivery_method == :letter_opener
    delivery_method LetterOpener::DeliveryMethod, location: Rails.root.join('tmp', 'letter_opener')
  else
    delivery_method :smtp, ActionMailer::Base.smtp_settings
  end
end
