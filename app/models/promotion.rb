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

  after_save :republish_content

  @@sparql = ::SPARQL::Client.new Figaro.env.sesame_rdf_endpoint

  mount_uploader :banner, ImageUploader

  #TODO: figure out this validation
  #validates_presence_of :banner
  validates_presence_of :publication

  def init
    self.active = true if self.active.nil?
  end

  # whenever a promotion is modified, we need to republish the content in case
  # it no longer qualifies as having a promotion (we have to update that feature
  # in the repo).
  def republish_content
    if content.present? and active
      mark_active_promotion
      # TODO: add logic here to check whether we're save removing the active promotion flag - 
      # I think this basically means the content has no active promotions at all.
    end
  end

  private
  def mark_active_promotion
    query = File.read('./lib/queries/add_active_promo.rq') % {content_id: content.id}
    @@sparql.update(query, { endpoint: Figaro.env.sesame_rdf_endpoint + "/statements"})
  end
end
