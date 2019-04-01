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

  validates_uniqueness_of :reverse_publish_email, :unsubscribe_email,
                          :subscribe_email, :post_email, allow_blank: true

  validates :reverse_publish_email, absence: { absence: true,
                                               message: "Can't populate `reverse_publish_email` for lists that are managed by Subtext." },
                                    if: :is_managed_list?
  validates :unsubscribe_email, :subscribe_email, :post_email, absence: { absence: true,
                                                                          message: "Can't populate these fields for lists that are managed by Vital Communities." },
                                                               if: :is_vc_list?

  validates :digest_reply_to, presence: true, if: :send_digest?
  validates :digest_send_time, presence: true, if: :send_digest?
  validates :forwarding_email, presence: true, if: :forward_for_processing?
  validates_presence_of :list_type

  validate :mc_group_name_required, if: :mc_list_id?

  validate :no_altering_queries
  validate :valid_template_name

  scope :active, -> { where(active: true) }

  scope :custom_digest, lambda {
    where(list_type: 'custom_digest')
  }

  DIGEST_TEMPLATES = Dir.entries('app/views/listserv_digest_mailer/').map { |file| file.split('.').first }.compact

  LIST_TYPES =
    [
      ['External List', 'external_list'],
      ['Internal List', 'internal_list'],
      ['Custom Digest', 'custom_digest']
    ].freeze

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

  def is_vc_list?
    reverse_publish_email.present?
  end

  def mc_sync?
    mc_list_id? && mc_group_name?
  end

  def no_altering_queries
    if digest_query?
      query_array = digest_query.upcase.split(' ')
      reserved_commands = %w[INSERT UPDATE DELETE DROP TRUNCATE]
      has_reserved_words = query_array.any? { |word| reserved_commands.include?(word) }
      errors.add(:digest_query, 'Commands to alter data are not allowed') if has_reserved_words
    end
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

  def internal_list?
    list_type.eql? 'internal_list'
  end

  def custom_digest?
    list_type.eql?('custom_digest') && digest_query?
  end

  def contents_from_custom_query
    custom_ids = custom_digest_results.map { |result| result['id'].to_i }
    Content.where(id: custom_ids).sort_by { |c| custom_ids.index(c.id) }
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

  def get_query
    ActiveRecord::Base.connection.execute(digest_query)
  end

  def custom_digest_results
    get_query.to_a
  end

  def mc_group_name_required
    if mc_list_id?
      unless mc_group_name?
        errors.add(:mc_group_name, 'required when mc_list_id present')
      end
    end
  end
end
