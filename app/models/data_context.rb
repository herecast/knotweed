class DataContext < ActiveRecord::Base

  has_many :datasets

  attr_accessible :archived, :context, :last_load, :loaded
end
