class Triple < ActiveRecord::Base
  attr_accessible :resource_class, :dataset_id, :object_class, :object_resource_id, 
                  :object_resource_text, :object_type, :predicate, :resource_id, 
                  :resource_text, :realm

  validates :object_type, inclusion: { in: %w(resource object literal) }
end
