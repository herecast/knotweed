class BusinessProfile < ActiveRecord::Base
  has_one :content, as: :channel
  accepts_nested_attributes_for :content
  validates_associated :content

  has_one :organization, through: :content

  belongs_to :business_location
  accepts_nested_attributes_for :business_location

  has_and_belongs_to_many :business_categories

  has_many :business_feedbacks

  attr_accessible :content_attributes, :business_location_attributes, :biz_type
end
