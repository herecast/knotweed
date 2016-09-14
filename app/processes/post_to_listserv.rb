# Receives [Listserv], [ReceivedEmail] and creates a categorized ListservContent record
class PostToListserv

  # @param [ReceivedEmail]
  # @return [ListservContent]
  def self.call(*args)
    self.new(*args).call
  end

  def initialize(listserv, email)
    @email = email
    @listserv = listserv
  end

  def call
    if sender_is_blacklisted?
      raise ListservExceptions::BlacklistedSender.new(@listserv, @email.from)
    end

    add_no_content_found if content_body_empty?
    begin
      content.content_category = DspClassify.call(content)
    rescue DspExceptions::UnableToClassify
      content.content_category = ContentCategory.find_or_create_by(name: 'market')
    end

    content.save!

    NotificationService.posting_verification(content)
    content.update verification_email_sent_at: Time.now

    return content
  end

  private

  def content
    @content ||= ListservContent.new(
      listserv: @listserv,
      sender_email: @email.from,
      sender_name: @email.sender_name,
      subject: @email.subject || "?",
      body: UgcSanitizer.call(@email.body),
      subscription: subscription,
      user: subscription.try(:user) || matching_user
    )
  end

  def subscription
    @subscription ||=
      Subscription.find_by(email: @email.from, listserv: @listserv)
  end

  def sender_is_blacklisted?
    !!subscription.try(:blacklist?)
  end

  def matching_user
    User.find_by(email: @email.from)
  end

  def content_body_empty?
    content.body == "" || empty_html? 
  end

  def empty_html?
    tmp = strip_tags(content.body)
    tmp.gsub!("\n", "")
    tmp == ""
  end

  def add_no_content_found
    content.body = "No content found"
    content.save!
  end

end
