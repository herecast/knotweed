# Service object responsible for adding and confirming subscription and syncing
# with Mailchimp
#
class SubscribeToListservSilently
  def self.call(*args)
    self.new(*args).call
  end

  def initialize(listserv, user, confirm_ip)
    @listserv = listserv
    @user = user
    @confirm_ip = confirm_ip
  end

  def call
    @subscription = Subscription.find_or_initialize_by({
      listserv: @listserv,
      email: @user.email
    })

    @subscription.name = @user.name
    @subscription.source = "knotweed"

    if !@subscription.confirmed?
      @subscription.confirm_ip = @confirm_ip
      @subscription.confirmed_at ||= Time.zone.now
      @subscription.unsubscribed_at = nil
      @subscription.save!
      sync_with_mc
    elsif @subscription.unsubscribed?
      @subscription.update! unsubscribed_at: nil
      sync_with_mc
    end


    if @subscription.persisted? && @subscription.confirmed?
      @subscription.save!
    end

    return @subscription
  end

  def sync_with_mc
    if @subscription.listserv.mc_sync?
      BackgroundJob.perform_later('MailchimpService', 'subscribe', @subscription)
    end
  end
  
end
