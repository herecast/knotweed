MailchimpAPI.configure do |config|
  if Rails.env.production? && ENV['STACK_NAME'] == 'knotweed-production'
    config.master_list_id = 'c3c399d570'
    config.mobile_blogger_interest_list_id = 'ab9e24de67'
    config.new_user_segment_id = '458813'
    config.new_blogger_segment_id = '458817'
  elsif ENV['MAILCHIMP_TEST'] == 'true'
    config.master_list_id = '8976c37a1c'
    config.mobile_blogger_interest_list_id = '9e8da81a56'
    config.new_user_segment_id = '454873'
    config.new_blogger_segment_id = '454877'
  else
    config.master_list_id = 'dummy-id'
    config.mobile_blogger_interest_list_id = 'dummy-id'
    config.new_user_segment_id = 'dummy-id'
    config.new_blogger_segment_id = 'dummy-id'
  end 
end