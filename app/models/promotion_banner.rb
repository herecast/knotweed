# == Schema Information
#
# Table name: promotion_banners
#
#  id               :integer          not null, primary key
#  banner_image     :string(255)
#  redirect_url     :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  campaign_start   :datetime
#  campaign_end     :datetime
#  max_impressions  :integer
#  impression_count :integer          default(0)
#  click_count      :integer          default(0)
#

class PromotionBanner < ActiveRecord::Base
  has_one :promotion, as: :promotable

  attr_accessible :banner_image, :redirect_url, :remove_banner, :banner_cache,
    :campaign_start, :campaign_end, :max_impressions, :impression_count,
    :click_count

  mount_uploader :banner_image, ImageUploader

  UPLOAD_ENDPOINT = "/statements"

  after_save :update_active_promotions
  before_destroy { |record| record.promotion.update_attribute :active, false; true }
  after_destroy :update_active_promotions

  validates_presence_of :promotion

  # this scope combines all conditions to determine whether a promotion banner is active
  # NOTE: we need the select clause or else the "joins" causes the scope to return 
  # readonly records.
  scope :active, includes(:promotion)
    .where('promotions.active = ?', true)
    .where('campaign_start <= ? OR campaign_start IS NULL', DateTime.now)
    .where('campaign_end >= ? OR campaign_end IS NULL', DateTime.now)
    .where('(impression_count < max_impressions OR max_impressions IS NULL)')

  # query promotion banners by content
  scope :for_content, lambda { |content_id| joins(:promotion).where('promotions.content_id = ?', content_id) }

  def update_active_promotions
    if promotion.content.present?
      # this is a little convoluted as we go to the content model
      # only to go back to the content's promotions...but in the interest
      # of code continuity, this allows us to change the logic in just once place
      # (Content.has_active_promotion?) that determines this.
      has_active_promo = promotion.content.has_active_promotion?

      promotion.content.repositories.each do |r|
        if has_active_promo
          PromotionBanner.mark_active_promotion(promotion.content, r)
        else
          remove_promotion(r)
        end
      end
    end
  end

  def self.mark_active_promotion(content, repo)
    query = File.read('./lib/queries/add_active_promo.rq') % {content_id: content.id}
    if repo.graphdb_endpoint.present?
      sparql = ::SPARQL::Client.new repo.graphdb_endpoint
      sparql.update(query, { endpoint: repo.graphdb_endpoint + UPLOAD_ENDPOINT })
    else
      sparql = ::SPARQL::Client.new repo.sesame_endpoint
      sparql.update(query, { endpoint: repo.sesame_endpoint + UPLOAD_ENDPOINT })
    end
  end

  def remove_promotion(repo)
    query = File.read('./lib/queries/remove_active_promo.rq') % {content_id: promotion.content.id}
    if repo.graphdb_endpoint.present?
      sparql = ::SPARQL::Client.new repo.graphdb_endpoint
      sparql.update(query, { endpoint: repo.graphdb_endpoint + UPLOAD_ENDPOINT })
    else
      sparql = ::SPARQL::Client.new repo.sesame_endpoint
      sparql.update(query, { endpoint: repo.sesame_endpoint + UPLOAD_ENDPOINT })
    end
  end

  # same as above method but called without a promotion
  def self.remove_promotion(repo, content_id)
    query = File.read('./lib/queries/remove_active_promo.rq') % {content_id: content_id}
    if repo.graphdb_endpoint.present?
      sparql = ::SPARQL::Client.new repo.graphdb_endpoint
      sparql.update(query, { endpoint: repo.graphdb_endpoint + UPLOAD_ENDPOINT })
    else
      sparql = ::SPARQL::Client.new repo.sesame_endpoint
      sparql.update(query, { endpoint: repo.sesame_endpoint + UPLOAD_ENDPOINT })
    end
  end
  
end
