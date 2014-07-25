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

  @@sparql = ::SPARQL::Client.new Figaro.env.sesame_rdf_endpoint
  @@upload_endpoint = Figaro.env.sesame_rdf_endpoint + "/statements"

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

      if has_active_promo
        mark_active_promotion
      else
        remove_promotion
      end
    end
  end

  private
  def mark_active_promotion
    query = File.read('./lib/queries/add_active_promo.rq') % {content_id: content.id}
    @@sparql.update(query, { endpoint: @@upload_endpoint })
  end

  def remove_promotion
    query = File.read('./lib/queries/remove_active_promo.rq') % {content_id: content.id}
    @@sparql.update(query, { endpoint: @@upload_endpoint })
  end
end
