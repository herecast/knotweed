require 'spec_helper'

describe ContentSet do
  describe "set_publishing_frequency" do
    it "should do nothing if publishing_frequency is set" do
      pub = FactoryGirl.create(:publication, publishing_frequency: Publication::FREQUENCY_OPTIONS[0])
      cset = FactoryGirl.create(:content_set, publishing_frequency: Publication::FREQUENCY_OPTIONS[1], publication: pub)
      cset.publishing_frequency.should == Publication::FREQUENCY_OPTIONS[1]
      cset.publishing_frequency.should_not == pub.publishing_frequency
    end
    it "should set publishing_frequency to its publication's if it is not set" do
      pub = FactoryGirl.create(:publication, publishing_frequency: Publication::FREQUENCY_OPTIONS[0])
      cset = FactoryGirl.create(:content_set, publication: pub)
      cset.publishing_frequency.should == Publication::FREQUENCY_OPTIONS[0]
      cset.publishing_frequency.should == pub.publishing_frequency
    end
  end
      
end
