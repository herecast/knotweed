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
#

require 'spec_helper'

describe Location do
  describe 'Location#find_by_city_state' do
    before do
      FactoryGirl.create :location, city: 'White River Junction', state: 'VT', consumer_active: true
      FactoryGirl.create :location, city: 'Hartford', state: 'CT', consumer_active: true
    end

    context 'args: find by city state' do
      before { @location = Location.find_by_city_state("White River Junction VT") }
      subject { @location }
      it { should_not be_nil }
    end

    context 'args: find by city, state' do
      before { @location = Location.find_by_city_state("White River Junction, VT") }
      subject { @location }
      it { should_not be_nil }
    end

    context 'args: find by city,state' do
      before { @location = Location.find_by_city_state("Hartford,CT") }
      subject { @location }
      it { should_not be_nil }
    end

    context 'args_with_space: find by city, state ' do
      before { @location = Location.find_by_city_state("Hartford,   CT   ") }
      subject { @location }
      it { should_not be_nil }
    end

    context 'args_with_space: find by city   state   ' do
      before { @location = Location.find_by_city_state("    Hartford    CT   ") }
      subject { @location }
      it { should_not be_nil }
    end

    context 'args: find by citystate' do
      before { @location = Location.find_by_city_state("White River JunctionVT") }
      subject { @location }
      it { should be_nil }
    end

    context 'args: find by city' do
      before { @location = Location.find_by_city_state("Hartford") }
      subject { @location }
      it { should_not be_nil }
    end

    context 'args_with_space: find by city' do
      before { @location = Location.find_by_city_state("  Hartford  ") }
      subject { @location }
      it { should_not be_nil }
    end

    context 'args_with_space: find by city, comma' do
      before { @location = Location.find_by_city_state("  Hartford,  ") }
      subject { @location }
      it { should_not be_nil }
    end

    context 'args: find by city,' do
      before { @location = Location.find_by_city_state("Hartford,") }
      subject { @location }
      it { should_not be_nil }
    end

    context 'args: empty' do
      before { @location = Location.find_by_city_state("") }
      subject { @location }
      it { should be_nil }
    end

  end
end
