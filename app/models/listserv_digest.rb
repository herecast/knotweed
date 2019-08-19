# frozen_string_literal: true

# == Schema Information
#
# Table name: listserv_digests
#
#  id               :integer          not null, primary key
#  listserv_id      :integer
#  mc_campaign_id   :string
#  sent_at          :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  from_name        :string
#  reply_to         :string
#  subject          :string
#  template         :string
#  sponsored_by     :string
#  location_ids     :integer          default([]), is an Array
#  subscription_ids :integer          default([]), is an Array
#  mc_segment_id    :string
#  title            :string
#  preheader        :string
#  promotion_ids    :integer          default([]), is an Array
#  content_ids      :integer          is an Array
#  emails_sent      :integer          default(0), not null
#  opens_total      :integer          default(0), not null
#  link_clicks      :hstore           not null
#  last_mc_report   :datetime
#  location_id      :bigint(8)
#
# Indexes
#
#  index_listserv_digests_on_listserv_id  (listserv_id)
#  index_listserv_digests_on_location_id  (location_id)
#
# Foreign Keys
#
#  fk_rails_...  (listserv_id => listservs.id)
#  fk_rails_...  (location_id => locations.id)
#

class ListservDigest < ActiveRecord::Base
  belongs_to :listserv
  belongs_to :location

  def contents=(contents)
    self.content_ids = contents.map(&:id)
    @contents = contents
  end

  def contents
    @contents ||=
      content_ids.present? ?
        Content.where(id: content_ids).sort_by { |c| content_ids.index(c.id) } : []
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
    frequency = listserv.digest_send_day? ? 'Weekly' : 'Daily'
    send_date = Date.today.strftime('%m_%d_%y')
    formatted_title = title.tr(' ', '_')
    tag = "#{frequency}_#{formatted_title}_#{send_date}"
    if tag.bytesize > 50
      "#{frequency}_#{formatted_title[0, 30]}_#{send_date}"
    else
      tag
    end
  end

  def promotions
    if promotion_ids.any?
      Promotion.where(id: promotion_ids).sort_by { |p| promotion_ids.index(p.id) }
    else
      []
    end
  end

  def clicks_for_promo(promotion)
    (link_clicks[promotion.promotable.redirect_url] || 0).to_i
  end
end
