# == Schema Information
#
# Table name: content_locations
#
#  id            :integer          not null, primary key
#  content_id    :integer
#  location_id   :integer
#  location_type :string
#  created_at    :datetime
#  updated_at    :datetime
#
# Indexes
#
#  index_content_locations_on_content_id   (content_id)
#  index_content_locations_on_location_id  (location_id)
#
# Foreign Keys
#
#  fk_rails_9ca11decb0  (content_id => contents.id)
#  fk_rails_cc6f358347  (location_id => locations.id)
#

class ContentLocation < ActiveRecord::Base
  belongs_to :content
  belongs_to :location

  TYPES = ['base', 'about']

  TYPES.each do |type|

    scope type.to_sym,-> { where(location_type: type) }

    define_method "#{type}?" do
      type.eql? location_type
    end

    define_method "#{type}!" do
      self.location_type = type
      self.save!
    end

  end
end
