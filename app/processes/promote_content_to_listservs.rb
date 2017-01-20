class PromoteContentToListservs
  # Handles promoting content to the listservs.
  # If the listserv is external, it sends reverse publish emails.
  # If the listserv is internal, it creates/updates a matching listserv_content
  # record.
  #
  # @param content [Content]
  # @param consumer_app [ConsumerApp]
  # @param remote_ip [String] - the client ip making the request.
  # @param listserv [Listserv] - continue to add more arguments for more listservs
  def self.call(*args)
    new(*args).call
  end

  def initialize(content, consumer_app, remote_ip, *listservs)
    @content = content
    @consumer_app = consumer_app
    @remote_ip = remote_ip
    @listservs = listservs
    @promotion_listservs = []
  end

  def call
    @listservs.each do |listserv|
      # need authoremail to send to lists
      if listserv.active? && @content.authoremail.present?
        @promotion_listservs << PromotionListserv.create_from_content(
          @content,
          listserv,
          @consumer_app
        )

        # Add locations from listserv to content
        listserv.add_listserv_location_to_content(@content)
      end
    end

    send_to_external_lists(
      @promotion_listservs.select{|pl| pl.listserv.is_vc_list?}
    )

    setup_for_internal_lists(
      @promotion_listservs.select{|pl| pl.listserv.is_managed_list?}
    )

  end

  protected
  def send_to_external_lists(promotion_listservs)
    vc_lists = promotion_listservs.collect(&:listserv)
    outbound_mail = ReversePublisher.mail_content_to_listservs(
      @content,
      vc_lists,
      @consumer_app
    )

    outbound_mail.deliver_later

    ReversePublisher.send_copy_to_sender_from_dailyuv(
      @content,
      outbound_mail.text_part.body.to_s,
      outbound_mail.html_part.body.to_s
    ).deliver_later

    PromotionListserv.where(id: promotion_listservs.collect(&:id)).update_all sent_at: Time.zone.now
  end

  def setup_for_internal_lists(promotion_listservs)
    promotion_listservs.each do |promo_list|
      list_content = ListservContent.where({
        listserv_id: promo_list.listserv_id,
        content_id: @content.id
      }).last

      if !list_content.present? || list_content.sent_in_digest?
        list_content = ListservContent.new({
          listserv: promo_list.listserv,
          content: @content
        })
      end

      list_content.update_from_content(@content)

      list_content.update!({
        verified_at: Time.current,
        verify_ip: @remote_ip
      })

      promo_list.update! listserv_content: list_content
      ensure_subscribed list_content
    end
  end

  def ensure_subscribed(listserv_content)
    subscription = SubscribeToListservSilently.call(
      listserv_content.listserv,
      @content.created_by,
      @remote_ip
    )

    listserv_content.update! subscription: subscription
  end
end
