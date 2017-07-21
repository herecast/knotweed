# == Schema Information
#
# Table name: promotion_listservs
#
#  id                  :integer          not null, primary key
#  listserv_id         :integer
#  sent_at             :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  listserv_content_id :integer
#

class PromotionListserv < ActiveRecord::Base
  has_one :promotion, as: :promotable
  belongs_to :listserv
  belongs_to :listserv_content

  validates_associated :promotion, :listserv

  # Creates a new promotion listserv record from a Content object and Listserv object.
  # Alternative would be to override ActiveRecord create method and add special handling
  # of these keys, but this seemed a little more straightforward.
  #
  # @param content [Content] the content object to associate the promotion with
  # @param listserv [Listserv] listserv object to associate the PromotionListserv with
  # @param consumer_app [ConsumerApp] for generating correct urls in emails
  # @return [PromotionListserv] the new PromotionListserv object
  def self.create_from_content(content, listserv, consumer_app=nil)
    if listserv.present? and listserv.active and content.authoremail.present?
      p = Promotion.create content: content
      p.promotable = PromotionListserv.new listserv_id: listserv.id
      p.save!

      # return promotable
      p.promotable
    else
      false
    end
  end
end
