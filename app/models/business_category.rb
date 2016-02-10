class BusinessCategory < ActiveRecord::Base
  has_and_belongs_to_many :business_profiles

  has_and_belongs_to_many :parents, class_name: 'BusinessCategory',
    join_table: :business_categories_business_categories,
    foreign_key: :parent_id, association_foreign_key: :child_id
  has_and_belongs_to_many :children, class_name: 'BusinessCategory',
    join_table: :business_categories_business_categories,
    foreign_key: :child_id, association_foreign_key: :parent_id

  attr_accessible :description, :icon_class, :name, :parent_ids, :child_ids

  validates_presence_of :name
end
