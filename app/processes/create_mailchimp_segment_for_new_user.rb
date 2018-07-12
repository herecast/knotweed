class CreateMailchimpSegmentForNewUser

  def self.call(*args)
    self.new(*args).call
  end

  def initialize(user)
    @user = user
  end

  def call
    MailchimpService::NewUser.subscribe_to_list(@user)
    create_user_specific_mc_segment
    add_user_to_user_specific_mc_segment
  end

  private

    def create_user_specific_mc_segment
      response = MailchimpService::NewUser.create_segment(@user)
      if response['id'].present?
        @user.update_attribute(:mc_segment_id, response['id'])
      else
        raise "Error creating Mailchimp segment for user with id: #{@user.id}"
      end
    end

    def add_user_to_user_specific_mc_segment
      response = MailchimpService::NewUser.add_to_segment(@user)
      if response['error_count'] > 0
        raise "Error adding user to user specific Mailchimp segment: #{response['errors'].join(', ')}"
      end
    end

end