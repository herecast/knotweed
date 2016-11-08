class Feature < ActiveRecord::Base
  validates :name, presence: true

  scope :active, -> { where(active: true) }
end
