require 'spec_helper'

describe Message do

  describe "active scope" do
    before do
      @active_message = FactoryGirl.create :message
      @expired_message = FactoryGirl.create :message, :inactive
      @not_yet_active_message = FactoryGirl.create :message, start_date: 1.week.from_now
    end

    it "should return only active messages" do
      Message.active.include?(@active_message).should == true
      Message.active.include?(@expired_message).should == false
      Message.active.include?(@not_yet_active_message).should == false
    end
  end

  describe "validation" do
    describe "end_date_greater_than_start_date" do
      it "should be invalid" do
        m = FactoryGirl.build(:message)
        m.end_date = m.start_date - 1.day
        m.should_not be_valid
      end
    end
  end

end
