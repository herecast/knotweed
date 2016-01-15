# == Schema Information
#
# Table name: content_categories
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  parent_id  :integer
#

class ContentCategory < ActiveRecord::Base
  attr_accessible :name

  has_many :contents

  belongs_to :parent, class_name: "ContentCategory"
  has_many :children, class_name: "ContentCategory", foreign_key: "parent_id"

  validates_uniqueness_of :name

  def label
    name.try :titlecase
  end

  def self.find_with_children(conditions)
    allowed_cats = ContentCategory.where(conditions)
    children = ContentCategory.where(parent_id: allowed_cats)
    allowed_cats + children
  end

  def self.event_categories
    ContentCategory.where(name: ["sale_event", "event"])
  end
end
