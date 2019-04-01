# frozen_string_literal: true

module MailchimpAPI
  include ActiveSupport::Configurable

  def mailchimp_connection
    Mailchimp::API.new(Figaro.env.mailchimp_api_key)
  end

  def mailchimp_config
    MailchimpAPI.config
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

  def conditionally_add_user_to_mailchimp_master_list(user)
    response = mailchimp_connection.lists.member_info(mailchimp_master_list_id,
                                                      [{ email: user.email }])
    unless response['success_count'] == 1 && \
           response['data'][0]['status'] == 'subscribed'
      subscribe_user_to_master_list(user)
    end
  end

  def subscribe_user_to_master_list(user)
    mailchimp_connection.lists.subscribe(mailchimp_master_list_id,
                                         { email: user.email }, nil, 'html', false)
  end

  def subscribe_email_to_mobile_blogger_interest_list(email)
    mailchimp_connection.lists.subscribe(mailchimp_config.mobile_blogger_interest_list_id,
      { email: email }, nil, 'html', false
    )
  end
end
