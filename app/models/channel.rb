class Channel < ActiveRecord::Base
  serialize :categories, Array
  attr_accessible :categories, :name



end
