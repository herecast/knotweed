# frozen_string_literal: true

module Outreach
  class AddUserToMailchimpMasterList
    include MailchimpAPI

    def self.call(*args)
      new(*args).call
    end

    def initialize(user, opts = {})
      @user = user
      @opts = opts
    end

    def call
      add_user_to_mailchimp_master_list
      add_user_to_new_user_segment
      add_user_to_new_blogger_segment if @opts[:new_blogger]
      true
    end

    private

    def add_user_to_mailchimp_master_list
      mailchimp_connection.lists.subscribe(mailchimp_config.master_list_id,
                                           { email: @user.email }, nil, 'html', false)
    rescue Mailchimp::ListAlreadySubscribedError
    end

    def add_user_to_new_user_segment
      mailchimp_connection.lists.static_segment_members_add(mailchimp_config.master_list_id,
                                                            mailchimp_config.new_user_segment_id,
                                                            [{ email: @user.email }])
    end

    def add_user_to_new_blogger_segment
      mailchimp_connection.lists.static_segment_members_add(mailchimp_config.master_list_id,
                                                            mailchimp_config.new_blogger_segment_id,
                                                            [{ email: @user.email }])
    end
  end
end
