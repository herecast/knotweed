# == Schema Information
#
# Table name: listserv_digests
#
#  id                   :integer          not null, primary key
#  listserv_id          :integer
#  mc_campaign_id       :string
#  sent_at              :datetime
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  from_name            :string
#  reply_to             :string
#  subject              :string
#  template             :string
#  sponsored_by         :string
#  location_ids         :integer          default([]), is an Array
#  subscription_ids     :integer          default([]), is an Array
#  mc_segment_id        :string
#  title                :string
#  preheader            :string
#  promotion_ids        :integer          default([]), is an Array
#  content_ids          :integer          is an Array
#  listserv_content_ids :integer          is an Array
#

class ListservDigest < ActiveRecord::Base
  belongs_to :listserv

  scope :has_listserv_content, ->( lc ) {
    where("? = ANY(listserv_content_ids)", lc.id)
  }

  def listserv_contents=contents
    self.listserv_content_ids = contents.map(&:id)
    @listserv_contents = contents
  end

  def listserv_contents
    @listserv_contents ||=
      listserv_content_ids.present? ?
        ListservContent.where(id: listserv_content_ids) : []
  end

  def contents=contents
    self.content_ids = contents.map(&:id)
    @contents = contents
  end

  def contents
    @contents ||=
      content_ids.present? ?
        Content.where(id: content_ids).sort_by{|c| content_ids.index(c.id)} : []
  end

  def locations=(list)
    write_attribute :location_ids, (list || []).collect(&:id).sort
  end

  def locations
    if location_ids.any?
      Location.where(id: location_ids)
    else
      []
    end
  end

  def subscriptions=(list)
    write_attribute :subscription_ids, (list || []).collect(&:id).sort
  end

  def subscriptions
    if subscription_ids.any?
      Subscription.where(id: subscription_ids)
    else
      []
    end
  end

  def subscriber_emails
    subscriptions.present? ? subscriptions.pluck(:email) : []
  end

  def ga_tag
    frequency = listserv.digest_send_day? ? "Weekly" : "Daily"
    send_date = Date.today.strftime("%m_%d_%y")
    formatted_title = title.gsub(' ', '_')
    tag = "#{frequency}_#{formatted_title}_#{send_date}"
    if tag.bytesize > 50
      "#{frequency}_#{formatted_title[0,30]}_#{send_date}"
    else
      tag
    end
  end

  def promotions
    if promotion_ids.any?
      Promotion.where(id: promotion_ids).sort_by {|p| promotion_ids.index(p.id) }
    else
      []
    end
  end
end
