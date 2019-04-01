MailchimpAPI.configure do |config|
  if Rails.env.production? && ENV['STACK_NAME'] == 'knotweed-production'
    config.mobile_blogger_interest_list_id = 'ab9e24de67'
  elsif ENV['MAILCHIMP_TEST'] == 'true'
    config.mobile_blogger_interest_list_id = '9e8da81a56'
  else
    config.mobile_blogger_interest_list_id = 'dummy-id'
  end 
end