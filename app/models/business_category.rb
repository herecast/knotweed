# == Schema Information
#
# Table name: business_categories
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  description :string(255)
#  icon_class  :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  source      :string(255)
#  source_id   :integer
#

class BusinessCategory < ActiveRecord::Base
  has_and_belongs_to_many :business_profiles

  has_and_belongs_to_many :parents, class_name: 'BusinessCategory',
    join_table: :business_categories_business_categories,
    foreign_key: :child_id, association_foreign_key: :parent_id
  has_and_belongs_to_many :children, class_name: 'BusinessCategory',
    join_table: :business_categories_business_categories,
    foreign_key: :parent_id, association_foreign_key: :child_id

  validates_presence_of :name

  # returns array of IDs of this category and all its children
  #
  # @return [Array] ids of business categories
  def full_descendant_ids
    response = [self.id]
    children.each do |c|
      response << c.full_descendant_ids
    end
    response.flatten
  end

  def name_with_parent
    parents.first.present? ? "#{parents.first.name} > #{name}" : name
  end

end
