class BusinessFeedback < ActiveRecord::Base
  include Auditable

  belongs_to :business_profile
  attr_accessible :business_profile_id, :satisfaction, :cleanliness,
    :price, :recommend
end
