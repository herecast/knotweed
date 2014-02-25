require 'spec_helper'

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
      
end
