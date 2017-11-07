# == Schema Information
#
# Table name: organization_locations
#
#  id              :integer          not null, primary key
#  organization_id :integer
#  location_id     :integer
#  location_type   :string
#  created_at      :datetime
#  updated_at      :datetime
#

require 'rails_helper'

RSpec.describe OrganizationLocation, type: :model do
  it { is_expected.to belong_to :organization }
  it { is_expected.to belong_to :location }
  it { is_expected.to have_db_column(:location_type).of_type(:string) }
end
