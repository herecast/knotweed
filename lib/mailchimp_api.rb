module MailchimpAPI

  def mailchimp_connection
    Mailchimp::API.new(Figaro.env.mailchimp_api_key)
  end

  def mailchimp_master_list_id
    Rails.configuration.subtext.email_outreach.new_user_list_id
  end
end