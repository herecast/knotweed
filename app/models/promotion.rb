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
    if content.present?
      content.repositories.each do |r|
        content.publish Content::POST_TO_ONTOTEXT, r
      end
    end
  end
end
