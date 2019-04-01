# frozen_string_literal: true

# == Schema Information
#
# Table name: business_feedbacks
#
#  id                  :bigint(8)        not null, primary key
#  created_by_id       :bigint(8)
#  updated_by_id       :bigint(8)
#  business_profile_id :bigint(8)
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

  after_commit -> { business_profile.update_feedback_cache! }
end
