# Confirms user acccount and any unconfirmed digest subscriptions for the user
class ConfirmRegistration

  def self.call(opts = {})
    user = User.confirm_by_token opts[:confirmation_token]
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
end
