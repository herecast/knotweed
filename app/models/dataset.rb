class Dataset < ActiveRecord::Base

  belongs_to :data_context

  attr_accessible :data_context_id, :description, :model_type, :name, :realm
end
