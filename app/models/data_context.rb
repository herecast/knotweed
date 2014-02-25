class DataContext < ActiveRecord::Base

  has_many :datasets

  default_scope { where archived: false }

  attr_accessible :archived, :context, :last_load, :loaded
end
