# frozen_string_literal: true

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
# Indexes
#
#  index_organization_locations_on_location_id      (location_id)
#  index_organization_locations_on_organization_id  (organization_id)
#
# Foreign Keys
#
#  fk_rails_...  (location_id => locations.id)
#  fk_rails_...  (organization_id => organizations.id)
#

require 'rails_helper'

RSpec.describe OrganizationLocation, type: :model do
  it { is_expected.to belong_to :organization }
  it { is_expected.to belong_to :location }
  it { is_expected.to have_db_column(:location_type).of_type(:string) }

  describe '#base?' do
    let(:ol) { FactoryGirl.create :organization_location, location_type: loc_type }
    subject { ol.base? }

    context 'for a base location' do
      let(:loc_type) { 'base' }
      it { expect(subject).to be true }
    end

    context 'for a non-base location' do
      let(:loc_type) { 'OTHER KIND' }
      it { expect(subject).to be false }
    end
  end

  describe '#base!' do
    let(:ol) { FactoryGirl.create :organization_location, location_type: 'some random type' }
    subject { ol.base! }

    it 'should change the location type to "base"' do
      expect { subject }.to change { ol.location_type }.to 'base'
    end
  end
end
