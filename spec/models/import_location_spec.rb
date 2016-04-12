# == Schema Information
#
# Table name: import_locations
#
#  id             :integer          not null, primary key
#  parent_id      :integer          default(0)
#  region_id      :integer          default(0)
#  city           :string(255)
#  state          :string(255)
#  zip            :string(255)
#  country        :string(128)
#  link_name      :string(255)
#  link_name_full :string(255)
#  status         :integer          default(0)
#  usgs_id        :string(128)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

require 'spec_helper'

describe ImportLocation, :type => :model do
  
  describe "find or create from match string" do

    it "should create a new location record with status pending" do
      query = "blarghus"
      loc = ImportLocation.find_or_create_from_match_string(query)
      expect(loc.city).to eq(query)
      expect(loc.status).to eq(ImportLocation::STATUS_REVIEW)
    end

    it "should match case insensitively on city" do
      loc = FactoryGirl.create(:import_location)
      expect(ImportLocation.find_or_create_from_match_string(loc.city)).to eq(loc)
    end

    it "should match a 'city state' composition" do
      loc = FactoryGirl.create(:import_location)
      expect(ImportLocation.find_or_create_from_match_string("#{loc.city} #{loc.state}")).to eq(loc)
    end

    it "should match 'city, state' removing any punctuation" do
      loc = FactoryGirl.create(:import_location, state: "VT")
      expect(ImportLocation.find_or_create_from_match_string("#{loc.city}, V.T.")).to eq(loc)
    end

    it "should return the parent of a match if parent is present" do
      parent = FactoryGirl.create(:import_location, city: "different from child")
      loc = FactoryGirl.create(:import_location, parent: parent)
      expect(ImportLocation.find_or_create_from_match_string(loc.city)).to eq(parent)
    end

  end

  describe "#name" do
    let(:subject) { FactoryGirl.create :import_location }

    it "returns formatted name for display" do
      expect(subject.name).to include subject.city, subject.state, subject.zip
    end
  end
end
