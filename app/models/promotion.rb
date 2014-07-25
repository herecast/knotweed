# == Schema Information
#
# Table name: promotions
#
#  id             :integer          not null, primary key
#  active         :boolean
#  banner         :string(255)
#  publication_id :integer
#  content_id     :integer
#  description    :text
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class Promotion < ActiveRecord::Base
  belongs_to :publication
  belongs_to :content
  # TODO: At some point we probably want to lock this down a bit more so it's not so easy to attach 
  # promotions to any content/publication
  attr_accessible :active, :banner, :banner_cache, :remove_banner, :description, :content, :publication,
                  :publication_id, :content_id
  after_initialize :init

  after_save :update_active_promotions
  before_destroy { |record| record.active = false; true }
  after_destroy :update_active_promotions

  UPLOAD_ENDPOINT = "/statements"

  mount_uploader :banner, ImageUploader

  #TODO: figure out this validation
  #validates_presence_of :banner
  validates_presence_of :publication

  def init
    self.active = true if self.active.nil?
  end

  def update_active_promotions
    if content.present?
      if active 
        has_active_promo = true
      else
        # Not totally atomic, but we'll live with that for now...
        has_active_promo = content.has_active_promotion?
      end

      content.repositories.each do |r|
        if has_active_promo
          mark_active_promotion(r)
        else
          remove_promotion(r)
        end
      end
    end
  end

  private
  def mark_active_promotion(repo)
    query = File.read('./lib/queries/add_active_promo.rq') % {content_id: content.id}
    sparql = ::SPARQL::Client.new repo.sesame_endpoint
    sparql.update(query, { endpoint: repo.sesame_endpoint + UPLOAD_ENDPOINT })
  end

  def remove_promotion(repo)
    query = File.read('./lib/queries/remove_active_promo.rq') % {content_id: content.id}
    sparql = ::SPARQL::Client.new repo.sesame_endpoint
    sparql.update(query, { endpoint: repo.sesame_endpoint + UPLOAD_ENDPOINT })
  end
end
