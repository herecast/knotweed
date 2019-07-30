# frozen_string_literal: true

# == Schema Information
#
# Table name: listservs
#
#  id                          :bigint(8)        not null, primary key
#  name                        :string(255)
#  reverse_publish_email       :string(255)
#  import_name                 :string(255)
#  active                      :boolean
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  digest_send_time            :time
#  unsubscribe_email           :string
#  post_email                  :string
#  subscribe_email             :string
#  mc_list_id                  :string
#  mc_group_name               :string
#  send_digest                 :boolean          default(FALSE)
#  last_digest_send_time       :datetime
#  last_digest_generation_time :datetime
#  digest_header               :text
#  digest_footer               :text
#  digest_reply_to             :string
#  timezone                    :string           default("Eastern Time (US & Canada)")
#  digest_description          :text
#  digest_send_day             :string
#  digest_query                :text
#  template                    :string
#  sponsored_by                :string
#  display_subscribe           :boolean          default(FALSE)
#  digest_subject              :string
#  digest_preheader            :string
#  list_type                   :string           default("custom_list")
#  sender_name                 :string
#  promotion_ids               :integer          default([]), is an Array
#  admin_email                 :string
#  forwarding_email            :string
#  forward_for_processing      :boolean          default(FALSE)
#  post_threshold              :integer          default(0)
#

class Listserv < ActiveRecord::Base
  include ListservSupport
  include HasPromotionForBanner

  has_many :promotion_listservs
  has_and_belongs_to_many :locations
  has_many :subscriptions
  has_many :campaigns

  validates_uniqueness_of :unsubscribe_email,
                          :subscribe_email, :post_email, allow_blank: true

  validates :digest_reply_to, presence: true, if: :send_digest?
  validates :digest_send_time, presence: true, if: :send_digest?
  validates :forwarding_email, presence: true, if: :forward_for_processing?

  validate :mc_group_name_required, if: :mc_list_id?

  validate :valid_template_name

  scope :active, -> { where(active: true) }

  DIGEST_TEMPLATES = Dir.entries('app/views/listserv_digest_mailer/').map { |file| file.split('.').first }.compact

  def mc_group_name=(n)
    write_attribute :mc_group_name, (n.nil? ? n : n.strip)
  end

  def promotions_list=(list)
    write_attribute(:promotion_ids, list.split(/[,\s]+/))
  end

  def promotions_list
    promotion_ids.join(', ')
  end

  def active_subscriber_count
    subscriptions.active.count
  end

  def is_managed_list?
    subscribe_email.present? || post_email.present? || unsubscribe_email.present?
  end

  def mc_sync?
    mc_list_id? && mc_group_name?
  end

  def valid_template_name
    if template? && DIGEST_TEMPLATES.exclude?(template)
      errors.add(:template, 'Please enter a valid template')
    end
  end

  def next_digest_send_time
    if digest_send_time? && !digest_send_day?
      tm = parse_digest_send_time
      tm.future? ? tm : tm.tomorrow
    elsif digest_send_time? && digest_send_day?
      tm = digest_send_time.strftime('%H:%M')
      Chronic.parse("#{digest_send_day} #{tm}")
    end
  end

  def banner_ads
    promotions.map(&:promotable) if promotions.any?
  end

  def self.digest_days
    %w[
      Sunday
      Monday
      Tuesday
      Wednesday
      Thursday
      Friday
      Saturday
    ]
  end

  def digest_contents(location_ids)
    news_category_id = ContentCategory.find_or_create_by(name: 'news').id
    content_ids = Organization
      .select('contents.id')
      .joins('INNER JOIN contents ON organizations.id = contents.organization_id')
      .joins('INNER JOIN locations ON contents.location_id = locations.id')
      .where('pubdate IS NOT NULL AND pubdate < NOW() AND pubdate >= ?', digest_date_bound)
      .where(contents: { root_content_category_id: news_category_id })
      .where(contents: { location_id: location_ids })
      .where('contents.id IN (
        SELECT id
        FROM contents
        WHERE organization_id = organizations.id AND pubdate >= ? AND pubdate < NOW() AND pubdate IS NOT NULL
        ORDER BY view_count DESC LIMIT 3
      )', digest_date_bound)
      .order('view_count DESC')
      .limit(12)
    Content.where(id: content_ids).order('view_count DESC')
  end

  def digest_date_bound
    # weekly
    if digest_send_day?
      1.week.ago
    else # daily
      30.hours.ago
    end
  end

  def promotions
    if promotion_ids.any?
      Promotion.where(id: promotion_ids).sort_by { |p| promotion_ids.index(p.id) }
    else
      []
    end
  end

  def parse_digest_send_time
    Time.zone.parse(digest_send_time.strftime('%H:%M'))
  end

  def mc_group_name_required
    if mc_list_id?
      unless mc_group_name?
        errors.add(:mc_group_name, 'required when mc_list_id present')
      end
    end
  end

  def locations
    Location.joins(users: [:subscriptions]).where(subscriptions: { listserv_id: id }).distinct
  end
end
