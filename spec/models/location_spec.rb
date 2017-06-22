# == Schema Information
#
# Table name: locations
#
#  id              :integer          not null, primary key
#  zip             :string(255)
#  city            :string(255)
#  state           :string(255)
#  slug            :string(255)
#  county          :string(255)
#  lat             :string(255)
#  long            :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  consumer_active :boolean          default(FALSE)
#  is_region       :boolean          default(FALSE)
#

require 'spec_helper'

describe Location, :type => :model do
  it {is_expected.to have_db_column(:is_region).of_type(:boolean)}

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

  describe 'Location#find_by_city_state' do
    before do
      FactoryGirl.create :location, city: 'White River Junction', state: 'VT', consumer_active: true
      FactoryGirl.create :location, city: 'Hartford', state: 'CT', consumer_active: true
    end

    context 'args: find by city state' do
      before { @location = Location.find_by_city_state("White River Junction VT") }
      subject { @location }
      it { is_expected.not_to be_nil }
    end

    context 'args: find by city, state' do
      before { @location = Location.find_by_city_state("White River Junction, VT") }
      subject { @location }
      it { is_expected.not_to be_nil }
    end

    context 'args: find by city,state' do
      before { @location = Location.find_by_city_state("Hartford,CT") }
      subject { @location }
      it { is_expected.not_to be_nil }
    end

    context 'args_with_space: find by city, state ' do
      before { @location = Location.find_by_city_state("Hartford,   CT   ") }
      subject { @location }
      it { is_expected.not_to be_nil }
    end

    context 'args_with_space: find by city   state   ' do
      before { @location = Location.find_by_city_state("    Hartford    CT   ") }
      subject { @location }
      it { is_expected.not_to be_nil }
    end

    context 'args: find by citystate' do
      before { @location = Location.find_by_city_state("White River JunctionVT") }
      subject { @location }
      it { is_expected.to be_nil }
    end

    context 'args: find by city' do
      before { @location = Location.find_by_city_state("Hartford") }
      subject { @location }
      it { is_expected.not_to be_nil }
    end

    context 'args: find by city multi word' do
      before { @location = Location.find_by_city_state("White River Junction") }
      subject { @location }
      it { is_expected.not_to be_nil }
    end

    context 'args_with_space: find by city' do
      before { @location = Location.find_by_city_state("  Hartford  ") }
      subject { @location }
      it { is_expected.not_to be_nil }
    end

    context 'args_with_space: find by city, comma' do
      before { @location = Location.find_by_city_state("  Hartford,  ") }
      subject { @location }
      it { is_expected.not_to be_nil }
    end

    context 'args: find by city,' do
      before { @location = Location.find_by_city_state("Hartford,") }
      subject { @location }
      it { is_expected.not_to be_nil }
    end

    context 'args: empty' do
      before { @location = Location.find_by_city_state("") }
      subject { @location }
      it { is_expected.to be_nil }
    end

    context 'args: nil' do
      before { @location = Location.find_by_city_state(nil) }
      subject { @location }
      it { is_expected.to be_nil }
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
        Geocoder::Calculations.distance_between([loc.lat.to_f,      loc.long.to_f],
                                                [location.lat.to_f, location.long.to_f])
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
        let!(:middle) { FactoryGirl.create :location, lat: 1.5, long: 1.5 }
        let!(:nearest) { FactoryGirl.create :location, lat: 0.1, long: 1 }
        let!(:furthest) { FactoryGirl.create :location, lat: 2, long: 2 }

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
end
