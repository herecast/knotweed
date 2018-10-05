# == Schema Information
#
# Table name: locations
#
#  id                              :integer          not null, primary key
#  zip                             :string(255)
#  city                            :string(255)
#  state                           :string(255)
#  county                          :string(255)
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  consumer_active                 :boolean          default(FALSE)
#  is_region                       :boolean          default(FALSE)
#  slug                            :string
#  latitude                        :float
#  longitude                       :float
#  default_location                :boolean          default(FALSE)
#  location_ids_within_five_miles  :integer          default([]), is an Array
#  location_ids_within_fifty_miles :integer          default([]), is an Array
#
# Indexes
#
#  index_locations_on_latitude_and_longitude  (latitude,longitude)
#

require 'spec_helper'

describe Location, :type => :model do
  it {is_expected.to have_db_column(:is_region).of_type(:boolean)}
  it { is_expected.to have_many :contents }
  it { is_expected.to have_many :organizations }
  it { is_expected.to have_many :organization_locations }
  it { is_expected.to validate_length_of(:state).is_equal_to(2) }

  describe "#slug" do
    it {is_expected.to have_db_column(:slug)}
    it {is_expected.to validate_uniqueness_of(:slug)}

    it 'is a dasherized city and state' do
      subject.city = "Wateroo Otte-Witte"
      subject.state = "UY"

      expect(subject.slug).to eq 'wateroo-otte-witte-uy'
    end

    it 'replaces non alphanumeric characters' do
      subject.state = "ID"
      subject.city = "Coeur d'Alene"

      expect(subject.slug).to eql 'coeur-d-alene-id'
    end
  end

  describe '.find_by_slug_or_id' do
    let!(:location) { FactoryGirl.create :location }

    context 'given slug' do
      it 'finds record' do
        expect(Location.find_by_slug_or_id(location.slug)).to eq location
      end
    end

    context 'given id' do
      it 'finds record' do
        expect(Location.find_by_slug_or_id(location.id)).to eq location
      end
    end
  end

  describe 'non_region' do
    let!(:region) {
      FactoryGirl.create :location, is_region: true
    }
    let!(:non_region) {
      FactoryGirl.create :location, is_region: false
    }
    subject { Location.non_region }

    it 'returns only locations not flagged is_region' do
      expect(subject).to include(non_region)
      expect(subject).to_not include(region)
    end
  end

  describe '#closest', elasticsearch: true do
    let(:location) { FactoryGirl.create :location, consumer_active: true }
    let!(:other_locations) { FactoryGirl.create_list :location, 3, consumer_active: true }

    it 'should not include the location itself' do
      expect(location.closest).to_not include location
    end

    it 'should return the specified number of results' do
      expect(location.closest(2).count).to eq 2
    end

    it 'should order results by distance' do
      # note, since `location` hasn't been called yet, this doesn't contain that record
      # so we don't have to worry about filtering it out
      locations_by_distance = Location.all.sort_by do |loc|
        Geocoder::Calculations.distance_between(loc.coordinates,
                                                location.coordinates)
      end
      expect(locations_by_distance).to eq location.closest
    end
  end

  describe '.nearest_to_coords' do
    context 'Given lat and lng' do
      let(:lat) { 0 }
      let(:lng) { 0 }

      subject {
        Location.nearest_to_coords(latitude: lat, longitude: lng)
      }

      context 'Locations exist varying distances away from coords' do
        let!(:middle) { FactoryGirl.create :location, latitude: 1.5, longitude: 1.5 }
        let!(:nearest) { FactoryGirl.create :location, latitude: 0.1, longitude: 1 }
        let!(:furthest) { FactoryGirl.create :location, latitude: 2, longitude: 2 }

        it 'locations in order of nearest first' do
          expect(subject.to_a).to match [nearest, middle, furthest]
        end
      end
    end
  end

  describe '.nearest_to_ip' do
    context 'Given an ip address' do
      let(:ip) { '127.1.0.4' }
      subject {
        Location.nearest_to_ip(ip)
      }

      context 'Geocoder returns a result for IP' do
        let(:result) { 
          Geocoder::Result::Base.new(
            latitude: 12.0012,
            longitude: 11.001
          )
        }

        before do
          allow(Geocoder).to receive(:search).with(ip).and_return(
            [result]
          )
        end

        it "returns locations nearest to result coordinates" do
          location = FactoryGirl.build(:location)

          expect(Location).to receive(:nearest_to_coords).with(
            latitude: result.latitude,
            longitude: result.longitude
          ).and_return([location])

          expect(subject.to_a).to eql [location]
        end
      end

      context 'Geocoder returns no result' do
        before do
          allow(Geocoder).to receive(:search).with(ip).and_return(
            []
          )
        end

        it 'returns empty array' do
          expect(subject).to be_empty
        end
      end
    end
  end

  describe '.within_radius_of' do
    context 'given a coordinates object, and radius (assumed miles)' do
      let(:coords) { [0, 0] }
      let(:radius) { 10 }

      subject { Location.within_radius_of(coords, radius) }

      it 'returns locations within the radius' do
        locations_within = 3.times.collect do
          FactoryGirl.create :location,
            coordinates: Geocoder::Calculations.random_point_near(
              coords,
              radius,
              unit: :mi
            )
        end

        locations_outside = 3.times.collect do
          FactoryGirl.create :location,
            coordinates: [
              (30..40).to_a.sample,
              (30..40).to_a.sample
            ]
        end

        expect(subject).to include *locations_within
        expect(subject).to_not include *locations_outside
      end
    end
  end
end
