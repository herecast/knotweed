require 'rails_helper'

RSpec.describe UpdateContentLocations do
  let(:content) {
    FactoryGirl.create :content
  }

  context 'Given content, base location and changed radius' do
    let!(:locations_within_radius) {
      FactoryGirl.create_list(:location, 3)
    }
    let(:base_location) {
      FactoryGirl.create(:location)
    }
    let(:radius) { 10 }

    before do
      allow(Location).to receive(:within_radius_of).with(base_location, radius).and_return(locations_within_radius)

      described_class.call content,
                           promote_radius: radius,
                           base_locations: [base_location]
    end

    it 'assigns correct content locations' do
      expect(content.content_locations.length).to eql 4

      base_locations = content.content_locations.select(&:base?)
      promoted_locations = content.content_locations.reject(&:base?)

      expect(base_locations.map(&:location_id)).to include base_location.id
      expect(promoted_locations.map(&:location_id)).to include *locations_within_radius.map(&:id)
    end

    it 'assigns the content#promote_radius' do
      expect(content.promote_radius).to eql radius
    end
  end
end
