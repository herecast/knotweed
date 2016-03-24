class BusinessProfile < ActiveRecord::Base
  has_one :content, as: :channel
  accepts_nested_attributes_for :content
  validates_associated :content

  belongs_to :business_location
  accepts_nested_attributes_for :business_location

  delegate :organization, to: :content

  has_and_belongs_to_many :business_categories

  has_many :business_feedbacks

  attr_accessible :content_attributes, :business_location_attributes, :has_retail_location,
    :business_category_ids, :business_location_id, :content_id

  # returns hash of aggregated feedbacks
  #
  # @return [Hash] average feedback values
  def feedback
    averages = business_feedbacks.select('AVG(satisfaction) sat, AVG(cleanliness) cle,' +
                                         'AVG(price) pri, AVG(recommend) rec').first
    {
      satisfaction: averages.sat,
      cleanliness: averages.cle,
      price: averages.pri,
      recommend: averages.rec
    }
  end
end
