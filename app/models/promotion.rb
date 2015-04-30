# == Schema Information
#
# Table name: promotions
#
#  id              :integer          not null, primary key
#  active          :boolean
#  publication_id  :integer
#  content_id      :integer
#  description     :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  promotable_id   :integer
#  promotable_type :string(255)
#

class Promotion < ActiveRecord::Base
  belongs_to :publication
  belongs_to :content

  belongs_to :promotable, polymorphic: true, inverse_of: :promotion

  # TODO: At some point we probably want to lock this down a bit more so it's not so easy to attach 
  # promotions to any content/publication
  attr_accessible :active, :description, :content, :publication,
                  :publication_id, :content_id, :target_url
  after_initialize :init

  UPLOAD_ENDPOINT = "/statements"

  def init
    self.active = true if self.active.nil?
  end

end
