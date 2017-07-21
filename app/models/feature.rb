# == Schema Information
#
# Table name: features
#
#  id          :integer          not null, primary key
#  name        :string
#  description :text
#  active      :boolean
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  options     :text
#

class Feature < ActiveRecord::Base
  validates :name, presence: true

  validate :validate_json, unless: Proc.new { |f| f.options.blank? }

  scope :active, -> { where(active: true) }

  # private

  def validate_json
    begin
      JSON.parse(self.options)
    rescue
      errors.add(:options, "Invalid JSON")
    end
  end
end
