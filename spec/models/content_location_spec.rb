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

require 'rails_helper'

RSpec.describe ContentLocation, type: :model do
  it { is_expected.to belong_to :content }
  it { is_expected.to belong_to :location }
  it { is_expected.to have_db_column(:location_type).of_type(:string) }
end
