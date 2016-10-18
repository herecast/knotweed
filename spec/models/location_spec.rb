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
end
