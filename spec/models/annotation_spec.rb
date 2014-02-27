require 'spec_helper'
require 'pp'

describe Annotation do
  describe "status" do
    it "should return 'accepted' when accepted is true" do
      ann = FactoryGirl.create(:annotation, accepted: true)
      ann.status.should== "accepted"
    end
    it "should return 'pending' when accepted is null" do
      ann = FactoryGirl.create(:annotation, accepted: nil)
      ann.status.should== "pending"
    end
    it "should return 'rejected' when accepted is false" do
      ann = FactoryGirl.create(:annotation, accepted: false)
      ann.status.should== "rejected"
    end
  end

  describe "edges" do
    it "should return nil when it has no lookup_class" do
      ann = FactoryGirl.create(:annotation, lookup_class: nil)
      ann.edges.should== nil
    end
    it "should return an nil when lookup class is bad" do
      ann = FactoryGirl.create(:annotation, lookup_class: "bad_lookup_class")
      ann.edges.should== nil
    end
    it "should return an empty list when lookup class is not found" do
      ann = FactoryGirl.create(:annotation, lookup_class: "http://www.subtext.org/resource/Company_T.12345")
      ann.edges.should== []
    end
    it "should return an non-empty list when lookup class is found" do
      ann = FactoryGirl.create(:annotation, lookup_class: "http://www.subtext.org/resource/Company_T.7685")
      ann.edges.length.should be >= 1
    end

  end
      
end
