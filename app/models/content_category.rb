# == Schema Information
#
# Table name: content_categories
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  parent_id  :integer
#  active     :boolean          default(TRUE)
#

class ContentCategory < ActiveRecord::Base
  has_many :contents

  belongs_to :parent, class_name: "ContentCategory"
  has_many :children, class_name: "ContentCategory", foreign_key: "parent_id"

  validates_uniqueness_of :name

  default_scope { where(active: true).order('UPPER(name) ASC') }

  def label
    name.try :titlecase
  end

end
