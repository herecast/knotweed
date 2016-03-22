# == Schema Information
#
# Table name: business_profiles
#
#  id                        :integer          not null, primary key
#  business_location_id      :integer
#  has_retail_location       :boolean          default(TRUE)
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  source                    :string(255)
#  source_id                 :integer
#  existence                 :integer
#  feedback_count            :integer          default(0)
#  feedback_recommend_avg    :float            default(0.0)
#  feedback_price_avg        :float            default(0.0)
#  feedback_satisfaction_avg :float            default(0.0)
#  feedback_cleanliness_avg  :float            default(0.0)
#

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

  def update_feedback_cache!
    fb = feedback_calc # cache db call
    self.feedback_price_avg = fb[:price]
    self.feedback_recommend_avg = fb[:recommend]
    self.feedback_satisfaction_avg = fb[:satisfaction]
    self.feedback_cleanliness_avg = fb[:cleanliness]
    self.feedback_count = business_feedbacks.size
    save!(validate: false)
  end

  private
  # returns hash of aggregated feedbacks
  #
  # @return [Hash] average feedback values
  def feedback_calc
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
