module MailchimpAPI

  def mailchimp_connection
    Mailchimp::API.new(Figaro.env.mailchimp_api_key)
  end

  def mailchimp_master_list_id
    Figaro.env.mailchimp_master_list_id
  end

  def new_user_segment_id
    Figaro.env.mailchimp_new_user_segment_id
  end

  def new_blogger_segment_id
    Figaro.env.mailchimp_new_blogger_segment_id
  end
end