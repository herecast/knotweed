# == Schema Information
#
# Table name: locations
#
#  id              :integer          not null, primary key
#  zip             :string(255)
#  city            :string(255)
#  state           :string(255)
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
        Geocoder::Calculations.distance_between([loc.lat,loc.long], [location.lat, location.long])
      end
      expect(locations_by_distance).to eq location.closest
    end
  end
end
