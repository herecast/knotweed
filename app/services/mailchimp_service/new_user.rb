module MailchimpService
  module NewUser
    extend self

    def subscribe_to_list(user)
      new_mailchimp_connection.lists.subscribe(list_id, {
                                                 email: user.email
                                               }, nil, 'html', false)
    end

    def create_segment(user)
      new_mailchimp_connection.lists.static_segment_add(list_id,
                                                        user.new_user_mc_segment_string)
    end

    def add_to_segment(user)
      new_mailchimp_connection.lists.static_segment_members_add(list_id,
                                                                user.mc_segment_id,
                                                                [{ email: user.email }])
    end

    private

    def new_mailchimp_connection
      Mailchimp::API.new(Figaro.env.mailchimp_api_key)
    end

    def list_id
      Rails.configuration.subtext.email_outreach.new_user_list_id
    end
  end
end
