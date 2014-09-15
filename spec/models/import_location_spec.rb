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

describe ImportLocation do
  
  describe "find or create from match string" do

    it "should create a new location record with status pending" do
      query = "blarghus"
      loc = ImportLocation.find_or_create_from_match_string(query)
      loc.city.should== query
      loc.status.should== ImportLocation::STATUS_REVIEW
    end

    it "should match case insensitively on city" do
      loc = FactoryGirl.create(:import_location)
      ImportLocation.find_or_create_from_match_string(loc.city).should== loc
    end

    it "should match a 'city state' composition" do
      loc = FactoryGirl.create(:import_location)
      ImportLocation.find_or_create_from_match_string("#{loc.city} #{loc.state}").should== loc
    end

    it "should match 'city, state' removing any punctuation" do
      loc = FactoryGirl.create(:import_location, state: "VT")
      ImportLocation.find_or_create_from_match_string("#{loc.city}, V.T.").should== loc
    end

    it "should return the parent of a match if parent is present" do
      parent = FactoryGirl.create(:import_location, city: "different from child")
      loc = FactoryGirl.create(:import_location, parent: parent)
      ImportLocation.find_or_create_from_match_string(loc.city).should== parent
    end

  end

end
