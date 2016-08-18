# == Schema Information
#
# Table name: promotion_listservs
#
#  id          :integer          not null, primary key
#  listserv_id :integer
#  sent_at     :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class PromotionListserv < ActiveRecord::Base
  has_one :promotion, as: :promotable
  belongs_to :listserv

  attr_accessible :listserv_id, :sent_at

  validates_associated :promotion, :listserv

  # Creates a new promotion listserv record from a Content object and Listserv object.
  # Alternative would be to override ActiveRecord create method and add special handling
  # of these keys, but this seemed a little more straightforward.
  #
  # @param content [Content] the content object to associate the promotion with
  # @param listserv [Listserv] listserv object to associate the PromotionListserv with
  # @return [PromotionListserv] the new PromotionListserv object
  def self.create_from_content(content, listserv, consumer_app=nil)
    if listserv.present? and listserv.active and content.authoremail.present?
      p = Promotion.create content: content
      p.promotable = PromotionListserv.new listserv_id: listserv.id
      p.save

      # send content emails
      listserv.send_content_to_listserv(content, consumer_app)
      p.promotable.update_attribute :sent_at, DateTime.current

      # return promotable
      p.promotable
    else
      false
    end
  end

  # Handles promotion of one piece of content to multiple listservs. Sends one email to 
  # all the listservs and creates promotion_listserv records for each.
  #
  # @param content [Content] the content object
  # @param listserv_ids [Array<Integer>] listserv IDs to use to lookup listservs
  # @return [Array<PromotionListserv>] the created PromotionListserv objects
  def self.create_multiple_from_content(content, listserv_ids, consumer_app=nil)
    return false unless content.authoremail.present? and listserv_ids.present? # need authoremail to send to lists
    listservs = Listserv.where(id: listserv_ids, active: true)

    outbound_mail = ReversePublisher.mail_content_to_listservs(content, listservs.to_a, consumer_app)
    outbound_mail.deliver_later
    sent_time = DateTime.current

    promotion_listservs = []

    listservs.each do |l|
      l.add_listserv_location_to_content(content) 
      # create PromotionListserv records
      p = Promotion.create content: content
      p.promotable = PromotionListserv.create listserv_id: l.id, sent_at: sent_time
      promotion_listservs << p
    end

    ReversePublisher.send_copy_to_sender_from_dailyuv(content, outbound_mail.text_part.body.to_s, outbound_mail.html_part.body.to_s).deliver_later

    promotion_listservs
  end

end
