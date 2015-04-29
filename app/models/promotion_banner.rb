class PromotionBanner < ActiveRecord::Base
  has_one :promotion, as: :promotable

  attr_accessible :banner_image, :promotion_id, :redirect_url, :remove_banner, :banner_cache

  mount_uploader :banner_image, ImageUploader

  after_save :update_active_promotions
  before_destroy { |record| record.active = false; true }
  after_destroy :update_active_promotions

  validates_presence_of :promotion

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
  
end
