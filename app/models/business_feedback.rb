# == Schema Information
#
# Table name: business_feedbacks
#
#  id                  :integer          not null, primary key
#  created_by          :integer
#  updated_by          :integer
#  business_profile_id :integer
#  satisfaction        :boolean
#  cleanliness         :boolean
#  price               :boolean
#  recommend           :boolean
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

class BusinessFeedback < ActiveRecord::Base
  include Auditable

  belongs_to :business_profile
  attr_accessible :business_profile_id, :satisfaction, :cleanliness,
    :price, :recommend

  after_commit -> { business_profile.update_feedback_cache! }
end
