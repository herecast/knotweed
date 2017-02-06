# Receives [ListservContent], [Hash].
# It sets verified state, updates attributes, sends post confirmation email.
class VerifyAndUpdateListservContent

  # @param [ListservContent] - content emailed to listserv.
  # @param [Hash] - Attributes to update on ListservContent record.
  # @return [Boolean] - Whether valid and saved.
  def self.call(*args)
    self.new(*args).call
  end

  def initialize(listserv_content, attributes = {})
    @model = listserv_content
    @attributes = attributes
  end

  def call
    ensure_not_verified

    @model.attributes= @attributes
    @model.verified_at = Time.current

    set_user if @attributes[:content_id].present?

    ensure_subscription_to_listserv
    ensure_subscription_not_blacklisted

    if @model.save
      RecordListservMetric.call('complete_metric', @model, @attributes)
      return true
    else
      return false
    end
  end

  private
  def ensure_not_verified
    if @model.verified?
      raise ListservExceptions::AlreadyVerified.new(@model)
    end
  end

  def set_user
    if @model.content
      if !@model.user_id?
        @model.user = @model.content.created_by
      elsif @model.user != @model.content.created_by
        raise ContentOwnerMismatch
      end
    end
  end

  def ensure_subscription_to_listserv
    @model.subscription ||= Subscription.find_or_create_by!(
      listserv: @model.listserv,
      email: @model.sender_email
    )

    @model.subscription.user = @model.user
    @model.subscription.name ||= @model.sender_name

    ConfirmSubscription.call(@model.subscription, @model.verify_ip)
    @model.subscription.save!
  end

  def ensure_subscription_not_blacklisted
    if @model.subscription.blacklist?
      raise ListservExceptions::BlacklistedSender.new(
        @model.listserv,
        @model.subscription.email
      )
    end
  end
end
