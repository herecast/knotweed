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
#

class PromotionBanner < ActiveRecord::Base
  include Incrementable

  has_one :promotion, as: :promotable
  has_many :content_promotion_banner_impressions
  has_many :contents, through: :content_promotion_banner_impressions
  has_many :promotion_banner_reports
  has_many :promotion_banner_metrics

  mount_uploader :banner_image, ImageUploader
  skip_callback :commit, :after, :remove_previously_stored_banner_image

  UPLOAD_ENDPOINT = "/statements"

  after_save :update_active_promotions
  after_destroy :update_active_promotions

  validates_presence_of :promotion, :banner_image, :campaign_start, :campaign_end, :promotion_type
  validates :max_impressions, numericality: {only_integer: true, greater_than: 0}, if: 'max_impressions.present?'
  validate :will_not_have_daily_and_per_impression_cost

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

  RUN_OF_SITE = "ROS"
  SPONSORED = "Sponsored"
  DIGEST = "Digest"
  NATIVE = "Native"
  PROMOTION_TYPES = [RUN_OF_SITE, SPONSORED, DIGEST, NATIVE]

  scope :run_of_site, -> { where(promotion_type: RUN_OF_SITE) }

  def active?
    campaign_start <= Time.current and campaign_end >= Time.current
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

  private

    def will_not_have_daily_and_per_impression_cost
      if cost_per_impression.present? && cost_per_day.present?
        errors.add(:cost_per_impression, 'cannot have cost_per_impression when cost_per_day is present')
      end
    end

end
