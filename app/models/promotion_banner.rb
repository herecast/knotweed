# == Schema Information
#
# Table name: promotion_banners
#
#  id                     :integer          not null, primary key
#  banner_image           :string(255)
#  redirect_url           :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  campaign_start         :date
#  campaign_end           :date
#  max_impressions        :integer
#  impression_count       :integer          default(0)
#  click_count            :integer          default(0)
#  daily_max_impressions  :integer
#  boost                  :boolean          default(FALSE)
#  daily_impression_count :integer          default(0)
#  load_count             :integer          default(0)
#  integer                :integer          default(0)
#  promotion_type         :string
#  cost_per_impression    :float
#  cost_per_day           :float
#  coupon_email_body      :text
#  coupon_image           :string
#  sales_agent            :string
#  digest_emails     :integer          default(0)
#  digest_clicks     :integer          default(0)
#  digest_opens      :integer          default(0)
#

class PromotionBanner < ActiveRecord::Base
  include Incrementable

  has_one :promotion, as: :promotable
  has_many :content_promotion_banner_impressions
  has_many :contents, through: :content_promotion_banner_impressions
  has_many :promotion_banner_reports
  has_many :promotion_banner_metrics

  mount_uploader :banner_image, ImageUploader
  mount_uploader :coupon_image, ImageUploader
  skip_callback :commit, :after, :remove_previously_stored_banner_image,
                                 :remove_previously_stored_coupon_image,
                                 :remove_banner_image!,
                                 :remove_coupon_image!

  UPLOAD_ENDPOINT = "/statements"

  after_save :generate_coupon_click_redirect
  after_save :update_active_promotions
  after_destroy :update_active_promotions

  validates_presence_of :promotion, :campaign_start, :campaign_end
  validates :max_impressions, numericality: { only_integer: true, greater_than: 0 }, if: 'max_impressions.present?'
  validates :daily_max_impressions, numericality: { only_integer: true, greater_than: 0 }, if: 'daily_max_impressions.present?'
  validates :cost_per_day, numericality: { greater_than: 0 }, if: 'cost_per_day.present?'
  validates :cost_per_impression, numericality: { greater_than: 0 }, if: 'cost_per_impression.present?'
  validate :presence_of_banner_image_if_necessary
  validate :will_not_have_daily_and_per_impression_cost
  validate :if_coupon_must_have_coupon_image

  OVER_DELIVERY_PERCENTAGE = 0.15

  # returns currently active promotion banners
  scope :active, ->(date=Date.current) { where("campaign_start <= ?", date)
    .where("campaign_end >= ?", date) }

  # this scope combines all conditions to determine whether a promotion banner is paid
  # NOTE: for now, we're just concerned with 'paid' and 'active' being true - will eventually
  # other conditions (campaign start/end, inventory)
  scope :paid, -> { includes(:promotion)
    .where('promotions.paid = ?', true).references(:promotion) }

 # this scope combines all conditions to determine whether a promotion banner has inventory
  # NOTE: we need the select clause or else the "joins" causes the scope to return
  # readonly records.
  scope :has_inventory, -> { includes(:promotion)
    .where('(impression_count < max_impressions OR max_impressions IS NULL)')
    .where("(daily_impression_count < (daily_max_impressions + (daily_max_impressions * #{OVER_DELIVERY_PERCENTAGE})) OR daily_max_impressions IS NULL)")
    .references(:promotion) }

 # this scope combines all conditions to determine whether a promotion banner is boosted
  # NOTE: we need the select clause or else the "joins" causes the scope to return
  # readonly records.
  scope :boost, -> { includes(:promotion)
    .where('boost = ?', true) }

  # query promotion banners by content
  scope :for_content, lambda { |content_id| joins(:promotion).where('promotions.content_id = ?', content_id) }

  # query promotion banners by multiple promotion ids
  scope :for_promotions, lambda { |promotion_ids| joins(:promotion).where(promotions: {:id =>  promotion_ids}) }

  RUN_OF_SITE = "ROS"
  SPONSORED = "Sponsored"
  DIGEST = "Digest"
  NATIVE = "Native"
  COUPON = "Coupon"
  PROFILE_PAGE = "Profile Page"
  PROMOTION_SERVICES = "Promotion Services"

  PROMOTION_TYPES = [RUN_OF_SITE, SPONSORED, DIGEST, NATIVE, COUPON, PROFILE_PAGE, PROMOTION_SERVICES]

  scope :run_of_site, -> { where(promotion_type: [RUN_OF_SITE, COUPON]) }

  scope :sunsetting, -> { where(campaign_end: Date.tomorrow) }

  def active?
    campaign_start <= Date.current && campaign_end >= Date.current
  end

  def has_inventory?
    has_daily_impressions_left? && has_total_impressions_left?
  end

  def active_with_inventory?
    active? && has_inventory?
  end

  def current_daily_report(current_date=Date.current)
    promotion_banner_reports.where("report_date >= ?", current_date).take
  end

  def find_or_create_daily_report(current_date=Date.current)
    current_daily_report(current_date) || promotion_banner_reports.create!(report_date: current_date)
  end

  def update_active_promotions
    if promotion.content.present?
      promotion.content.repositories.each do |r|
        active_action = promotion.content.has_active_promotion? ? 'add_active' : 'remove_active'
        DspService.update_promotion(active_action, promotion.content.id, r)

        paid_action = promotion.content.has_paid_promotion? ? 'add_paid' : 'remove_paid'
        DspService.update_promotion(paid_action, promotion.content.id, r)
      end
    end
  end

  def remove_coupon_image=(val)
    coupon_image_will_change! if val
    super
  end

  def remove_banner_image=(val)
    banner_image_will_change! if val
    super
  end

  def total_impressions_allowed
    if campaign_start.present? && campaign_end.present?
      ((campaign_end - campaign_start).to_i + 1) * (daily_max_impressions || 0)
    else
      0
    end
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

    def generate_coupon_click_redirect
      new_redirect_url = "/promotions/#{id}"
      if promotion_type == COUPON && redirect_url != new_redirect_url
        update_attribute :redirect_url, new_redirect_url
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
