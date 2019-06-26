# frozen_string_literal: true
# == Schema Information
#
# Table name: promotion_banners
#
#  id                     :bigint(8)        not null, primary key
#  banner_image           :string(255)
#  redirect_url           :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  campaign_start         :date
#  campaign_end           :date
#  max_impressions        :bigint(8)
#  impression_count       :bigint(8)        default(0)
#  click_count            :bigint(8)        default(0)
#  daily_max_impressions  :bigint(8)
#  boost                  :boolean          default(FALSE)
#  daily_impression_count :bigint(8)        default(0)
#  load_count             :integer          default(0)
#  integer                :integer          default(0)
#  promotion_type         :string
#  cost_per_impression    :float
#  cost_per_day           :float
#  coupon_email_body      :text
#  coupon_image           :string
#  sales_agent            :string
#  digest_clicks          :integer          default(0), not null
#  digest_opens           :integer          default(0), not null
#  digest_emails          :integer          default(0), not null
#  digest_metrics_updated :datetime
#  location_id            :bigint(8)
#
# Indexes
#
#  index_promotion_banners_on_location_id  (location_id)
#
# Foreign Keys
#
#  fk_rails_...  (location_id => locations.id)
#

class PromotionBanner < ActiveRecord::Base
  include Incrementable

  has_one :promotion, as: :promotable
  has_many :content_promotion_banner_impressions
  has_many :contents, through: :content_promotion_banner_impressions
  has_many :promotion_banner_reports
  has_many :promotion_banner_metrics
  belongs_to :location

  mount_uploader :banner_image, ImageUploader
  mount_uploader :coupon_image, ImageUploader
  skip_callback :commit, :after, :remove_previously_stored_banner_image,
                :remove_previously_stored_coupon_image,
                :remove_banner_image!,
                :remove_coupon_image!, raise: false

  UPLOAD_ENDPOINT = '/statements'

  validates_presence_of :promotion, :campaign_start, :campaign_end
  validates :max_impressions, numericality: { only_integer: true, greater_than: 0 }, if: -> { max_impressions.present? }
  validates :daily_max_impressions, numericality: { only_integer: true, greater_than: 0 }, if: -> { daily_max_impressions.present? }
  validates :cost_per_day, numericality: { greater_than: 0 }, if: -> { cost_per_day.present? }
  validates :cost_per_impression, numericality: { greater_than: 0 }, if: -> { cost_per_impression.present? }
  validates :location_id, presence: true, if: -> { promotion_type == TARGETED }
  validate :presence_of_banner_image_if_necessary
  validate :will_not_have_daily_and_per_impression_cost
  validate :if_coupon_must_have_coupon_image

  OVER_DELIVERY_PERCENTAGE = 0.15

  # returns currently active promotion banners
  scope :active, lambda { |date = Date.current|
                   where('campaign_start <= ?', date)
                     .where('campaign_end >= ?', date)
                 }

  # this scope combines all conditions to determine whether a promotion banner is paid
  # NOTE: for now, we're just concerned with 'paid' and 'active' being true - will eventually
  # other conditions (campaign start/end, inventory)
  scope :paid, lambda {
                 includes(:promotion)
                   .where('promotions.paid = ?', true).references(:promotion)
               }

  # this scope combines all conditions to determine whether a promotion banner has inventory
  # NOTE: we need the select clause or else the "joins" causes the scope to return
  # readonly records.
  scope :has_inventory, lambda {
                          includes(:promotion)
                            .where('(impression_count < max_impressions OR max_impressions IS NULL)')
                            .where("(daily_impression_count < (daily_max_impressions + (daily_max_impressions * #{OVER_DELIVERY_PERCENTAGE})) OR daily_max_impressions IS NULL)")
                            .references(:promotion)
                        }

  # this scope combines all conditions to determine whether a promotion banner is boosted
  # NOTE: we need the select clause or else the "joins" causes the scope to return
  # readonly records.
  scope :boost, lambda {
                  includes(:promotion)
                    .where('boost = ?', true)
                }

  # query promotion banners by content
  scope :for_content, ->(content_id) { joins(:promotion).where('promotions.content_id = ?', content_id) }

  # query promotion banners by multiple promotion ids
  scope :for_promotions, ->(promotion_ids) { joins(:promotion).where(promotions: { id: promotion_ids }) }

  TARGETED = 'Targeted'
  RUN_OF_SITE = 'ROS'
  SPONSORED = 'Sponsored'
  DIGEST = 'Digest'
  NATIVE = 'Native'
  COUPON = 'Coupon'
  PROFILE_PAGE = 'Profile Page'
  PROMOTION_SERVICES = 'Promotion Services'
  PACKAGE_LAUNCH = 'Package: Launch'
  PACKAGE_MAINTENANCE = 'Package: Maintenance'
  PACKAGE_PLUS = 'Package: Plus'
  PACKAGE_PRESENCE = 'Package: Presence'
  PACKAGE_PROMINENCE = 'Package: Prominence'

  PROMOTION_TYPES = [
    TARGETED,
    RUN_OF_SITE,
    SPONSORED,
    DIGEST,
    NATIVE,
    COUPON,
    PROFILE_PAGE,
    PROMOTION_SERVICES,
    PACKAGE_LAUNCH,
    PACKAGE_MAINTENANCE,
    PACKAGE_PLUS,
    PACKAGE_PRESENCE,
    PACKAGE_PROMINENCE
  ].freeze

  scope :run_of_site, -> { where(promotion_type: [RUN_OF_SITE, COUPON]) }

  scope :sunsetting, -> { where(campaign_end: Date.tomorrow) }

  def redirect_url
    promotion_type == COUPON ? "/promotions/#{id}" : read_attribute(:redirect_url)
  end

  def active?
    campaign_start <= Date.current && campaign_end >= Date.current
  end

  def has_inventory?
    has_daily_impressions_left? && has_total_impressions_left?
  end

  def active_with_inventory?
    active? && has_inventory?
  end

  def current_daily_report(current_date = Date.current)
    promotion_banner_reports.where('report_date >= ?', current_date).take
  end

  def find_or_create_daily_report(current_date = Date.current)
    current_daily_report(current_date) || promotion_banner_reports.create!(report_date: current_date)
  end

  private

  def will_not_have_daily_and_per_impression_cost
    if cost_per_impression.present? && cost_per_day.present?
      errors.add(:cost_per_impression, 'cannot have cost_per_impression when cost_per_day is present')
    end
  end

  def if_coupon_must_have_coupon_image
    if promotion_type == COUPON && coupon_image.file.blank?
      errors.add(:coupon_image, 'type coupon must have coupon image')
    end
  end

  def presence_of_banner_image_if_necessary
    unless [PROMOTION_SERVICES, PROFILE_PAGE].include?(promotion_type)
      unless banner_image.present?
        errors.add(:banner_image, 'creative must have banner image')
      end
    end
  end

  def total_daily_allowable_impressions
    daily_max_impressions + (daily_max_impressions * OVER_DELIVERY_PERCENTAGE)
  end

  def has_daily_impressions_left?
    daily_max_impressions.present? ? daily_impression_count < total_daily_allowable_impressions : true
  end

  def has_total_impressions_left?
    max_impressions.present? ? impression_count < max_impressions : true
  end
end
