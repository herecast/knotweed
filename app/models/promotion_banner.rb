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
#

class PromotionBanner < ActiveRecord::Base
  include Incrementable

  has_one :promotion, as: :promotable
  has_many :content_promotion_banner_impressions
  has_many :contents, through: :content_promotion_banner_impressions
  has_many :promotion_banner_reports

  attr_accessible :banner_image, :redirect_url, :remove_banner, :banner_cache,
    :campaign_start, :campaign_end, :max_impressions, :impression_count,
    :click_count, :boost, :daily_max_impressions, :daily_impression_count

  mount_uploader :banner_image, ImageUploader

  UPLOAD_ENDPOINT = "/statements"

  after_save :update_active_promotions
  before_destroy { |record| record.promotion.update_attribute :active, false; true }
  after_destroy :update_active_promotions

  validates_presence_of :promotion
  validates :max_impressions, numericality: {only_integer: true, greater_than: 0}, if: 'max_impressions.present?'
#  validates :daily_max_impressions, numericality: {only_integer: true, greater_than: 0}, if: 'daily_max_impressions.present?'

  # @deprecated as of release 3.0.3
  # this scope combines all conditions to determine whether a promotion banner is active
  # NOTE: we need the select clause or else the "joins" causes the scope to return 
  # readonly records.
  scope :active, -> { includes(:promotion)
    .where('campaign_start <= ?', DateTime.now)
    .where('campaign_end >= ?', DateTime.now).references(:promotion) }

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
    .where('(daily_impression_count < daily_max_impressions OR daily_max_impressions IS NULL)')
    .references(:promotion) }

 # this scope combines all conditions to determine whether a promotion banner is boosted
  # NOTE: we need the select clause or else the "joins" causes the scope to return
  # readonly records.
  scope :boost, -> { includes(:promotion)
    .where('boost = ?', true) }

  # query promotion banners by content
  scope :for_content, lambda { |content_id| joins(:promotion).where('promotions.content_id = ?', content_id) }

  def update_active_promotions
    if promotion.content.present?
      # this is a little convoluted as we go to the content model
      # only to go back to the content's promotions...but in the interest
      # of code continuity, this allows us to change the logic in just once place
      # (Content.has_active_promotion?) that determines this.
      # Extended this to include updating 'paid' promos.
      has_active_promo = promotion.content.has_active_promotion?
      has_paid_promo = promotion.content.has_paid_promotion?

      # update each repo storing content
      promotion.content.repositories.each do |r|
        if has_active_promo
          PromotionBanner.mark_active_promotion(promotion.content, r)
        else
          remove_promotion(r)
        end
      end
      # update 'hasPaidPromotion' flag
      promotion.content.repositories.each do |r|
        if has_paid_promo
          PromotionBanner.mark_paid_promotion(promotion.content, r)
        else
          remove_paid_promotion(r)
        end
      end
    end
  end

  def self.mark_active_promotion(content, repo)
    query = File.read('./lib/queries/add_active_promo.rq') % {content_id: content.id}
    sparql = ::SPARQL::Client.new repo.graphdb_endpoint
    sparql.update(query, { endpoint: repo.graphdb_endpoint + UPLOAD_ENDPOINT })
  end

  def remove_promotion(repo)
    query = File.read('./lib/queries/remove_active_promo.rq') % {content_id: promotion.content.id}
    sparql = ::SPARQL::Client.new repo.graphdb_endpoint
    sparql.update(query, { endpoint: repo.graphdb_endpoint + UPLOAD_ENDPOINT })
  end

  # same as above method but called without a promotion
  def self.remove_promotion(repo, content_id)
    query = File.read('./lib/queries/remove_active_promo.rq') % {content_id: content_id}
    sparql = ::SPARQL::Client.new repo.graphdb_endpoint
    sparql.update(query, { endpoint: repo.graphdb_endpoint + UPLOAD_ENDPOINT })
  end

  def self.mark_paid_promotion(content, repo)
    query = File.read('./lib/queries/add_paid_promo.rq') % {content_id: content.id}
    sparql = ::SPARQL::Client.new repo.graphdb_endpoint
    sparql.update(query, { endpoint: repo.graphdb_endpoint + UPLOAD_ENDPOINT })
  end

  def remove_paid_promotion(repo)
    query = File.read('./lib/queries/remove_paid_promo.rq') % {content_id: promotion.content.id}
    sparql = ::SPARQL::Client.new repo.graphdb_endpoint
    sparql.update(query, { endpoint: repo.graphdb_endpoint + UPLOAD_ENDPOINT })
  end

  # same as above method but called without a promotion
  def self.remove_paid_promotion(repo, content_id)
    query = File.read('./lib/queries/remove_paid_promo.rq') % {content_id: content_id}
    sparql = ::SPARQL::Client.new repo.graphdb_endpoint
    sparql.update(query, { endpoint: repo.graphdb_endpoint + UPLOAD_ENDPOINT })
  end

end
