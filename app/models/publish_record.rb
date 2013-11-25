class PublishRecord < ActiveRecord::Base
  belongs_to :publish_job
  has_and_belongs_to_many :contents
  attr_accessible :failures, :items_published
end
