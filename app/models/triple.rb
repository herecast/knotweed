# == Schema Information
#
# Table name: triples
#
#  id                   :integer          not null, primary key
#  dataset_id           :integer
#  resource_class       :string(255)
#  resource_id          :integer
#  resource_text        :string(255)
#  predicate            :string(255)
#  object_type          :string(255)
#  object_class         :string(255)
#  object_resource_id   :integer
#  object_resource_text :string(255)
#  realm                :string(255)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#

class Triple < ActiveRecord::Base
  attr_accessible :resource_class, :dataset_id, :object_class, :object_resource_id, 
                  :object_resource_text, :object_type, :predicate, :resource_id, 
                  :resource_text, :realm

  validates :object_type, inclusion: { in: %w(resource object literal) }
end
