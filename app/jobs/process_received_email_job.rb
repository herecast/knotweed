class ProcessReceivedEmailJob < ActiveJob::Base
  queue_as :default

  def perform(email)
    @email = email

    unless @email.to.present? && @email.from.present?
      @email.preprocess
    end

    determine_email_purpose

    begin
      case @email.purpose.to_sym
        when :subscribe_to_listserv
          process_subscribe_action
        when :unsubscribe_from_listserv
          process_unsubscribe_action
        when :post_to_listserv
          process_post_action
        else
          @email.result = "Cannot process, unknown purpose"
      end
      @email.processed_at = Time.now
    rescue Exception => e
      @email.result = e.message + '\n' + e.backtrace.join('\n')
      Rails.logger.error(e.message)
      Rails.logger.error(e.backtrace.join('\n'))
      raise e
    ensure
      @email.save!
    end
  end

  protected

  def determine_email_purpose
    if Listserv.where(subscribe_email: @email.to).exists?
      @email.purpose = :subscribe_to_listserv
    elsif Listserv.where(unsubscribe_email: @email.to).exists?
      @email.purpose = :unsubscribe_from_listserv
    elsif Listserv.where(post_email: @email.to).exists?
      @email.purpose = :post_to_listserv
    else
      @email.purpose = :unknown
    end
  end

  def process_subscribe_action
    listserv = Listserv.find_by(subscribe_email: @email.to)
    subscription = SubscribeToListserv.call(listserv, {
      email: @email.from,
      name: @email.sender_name,
      source: "email"
    })

    @email.record = subscription
    @email.result = "Subscription processed"
  end

  def process_unsubscribe_action
    listserv = Listserv.find_by(unsubscribe_email: @email.to)
    if listserv
      subscription = Subscription.find_by({
        email: @email.from,
        listserv_id: listserv.id
      })

      if subscription
        subscription.unsubscribed_at = @email.created_at
        subscription.save!
        @email.result = "Unsubscribe completed"
      end
    end
  end

  def process_post_action
    listserv = Listserv.find_by(post_email: @email.to)
    listserv_content = PostToListserv.call(listserv, @email)
    RecordListservMetric.call('create_metric', listserv_content)
    @email.record = listserv_content
    @email.result = "Posted to Listserv"
  rescue ListservExceptions::BlacklistedSender => e
    @email.result = e.message
  end
end
