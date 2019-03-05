# frozen_string_literal: true

module MailchimpService
  module NewUser
    include MailchimpAPI
    extend self

    def subscribe_to_list(user)
      mailchimp_connection.lists.subscribe(mailchimp_master_list_id, {
                                                 email: user.email
                                               }, nil, 'html', false)
    end

    def create_segment(user)
      mailchimp_connection.lists.static_segment_add(mailchimp_master_list_id,
                                                        user.new_user_mc_segment_string)
    end

    def add_to_segment(user)
      mailchimp_connection.lists.static_segment_members_add(mailchimp_master_list_id,
                                                                user.mc_segment_id,
                                                                [{ email: user.email }])
    end
  end
end
