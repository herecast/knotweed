class BusinessFeedback < ActiveRecord::Base
  include Auditable

  belongs_to :business_profile

  after_commit -> { business_profile.update_feedback_cache! }
end
