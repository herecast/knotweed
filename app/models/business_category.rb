class BusinessCategory < ActiveRecord::Base
  has_and_belongs_to_many :business_profiles
  has_many :children, class_name: 'BusinessCategory', foreign_key: :parent_id
  belongs_to :parent, class_name: 'BusinessCategory'

  attr_accessible :description, :icon_class, :name, :parent_id

  validates_presence_of :name
end
