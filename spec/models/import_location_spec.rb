require 'spec_helper'

describe ImportLocation do
  
  describe "find or create from match string should operate according to spec" do

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
