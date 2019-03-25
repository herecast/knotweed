# frozen_string_literal: true

# Confirms user acccount and any unconfirmed digest subscriptions for the user
class ConfirmRegistration
  def self.call(opts = {})
    user = User.confirm_by_token opts[:confirmation_token]
    add_user_to_master_list(user)
    if user.unconfirmed_subscriptions?
      user.unconfirmed_subscriptions.each do |sub|
        sub.confirm_ip = opts[:confirm_ip]
        sub.confirmed_at ||= Time.zone.now
        sub.save!
        BackgroundJob.perform_later('MailchimpService', 'subscribe', sub)
      end
    end
    user
  end

  private

  def self.add_user_to_master_list(user)
    if user.persisted?
      BackgroundJob.perform_later(
        'Outreach::AddUserToMailchimpMasterList',
        'call',
        user
      )
    end
  end
end
