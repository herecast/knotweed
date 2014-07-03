class Category < ActiveRecord::Base
  attr_accessible :channel_id, :name

  belongs_to :channel
end
