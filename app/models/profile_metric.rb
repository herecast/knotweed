class ProfileMetric < ActiveRecord::Base
  belongs_to :organization
  belongs_to :location
  belongs_to :user
  belongs_to :content

  validates :content_id, presence: true, if: ->(inst){ inst.event_type.eql?("click") }
end
