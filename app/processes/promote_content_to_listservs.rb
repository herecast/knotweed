class PromoteContentToListservs
  include EmailTemplateHelper
  include ContentsHelper
  include MarketPostsHelper

  # Handles promoting content to the listservs.
  # If the listserv is external, it sends reverse publish emails.
  #
  # @param content [Content]
  # @param remote_ip [String] - the client ip making the request.
  # @param listserv [Listserv] - continue to add more arguments for more listservs
  def self.call(*args)
    new(*args).call
  end

  def initialize(content, remote_ip, *listservs)
    @content = content
    @remote_ip = remote_ip
    @listservs = listservs
    @promotion_listservs = []
  end

  def call
    if @content.channel.is_a? MarketPost
      content_link = market_post_url_for_email(@content.channel)
    else
      content_link = content_url_for_email(@content)
    end
    short_link = BitlyService.create_short_link(content_link)
    @content.update_attributes(short_link: short_link)
    @listservs.each do |listserv|
      # need authoremail to send to lists
      if listserv.active? && @content.authoremail.present?
        @promotion_listservs << PromotionListserv.create_from_content(
          @content,
          listserv
        )
      end
    end

    send_to_external_lists(
      @promotion_listservs.select { |pl| pl.listserv.is_vc_list? }
    )
  end

  protected

  def send_to_external_lists(promotion_listservs)
    vc_lists = promotion_listservs.collect(&:listserv)
    outbound_mail = ReversePublisher.mail_content_to_listservs(
      @content,
      vc_lists
    )

    outbound_mail.deliver_later

    ReversePublisher.send_copy_to_sender_from_dailyuv(
      @content,
      outbound_mail.text_part.body.to_s,
      outbound_mail.html_part.body.to_s
    ).deliver_later

    PromotionListserv.where(id: promotion_listservs.collect(&:id)).update_all sent_at: Time.zone.now
  end
end
