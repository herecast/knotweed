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
    if listserv.active and content.authoremail.present?
      p = Promotion.create content: content
      p.promotable = PromotionListserv.new listserv_id: listserv.id
      p.save

      # send content emails
      listserv.send_content_to_listserv(content, consumer_app)
      p.promotable.update_attribute :sent_at, DateTime.now

      # return promotable
      p.promotable
    else
      false
    end
  end

end
