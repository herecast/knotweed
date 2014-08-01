require 'spec_helper'

describe ContentsController do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end
  describe "POST create" do
    describe "an event" do
      it "parses start and end date fields appropriately when no end day is provided" do
        post :create, content: FactoryGirl.attributes_for(:event, start_date: nil, end_date: nil),
          start_day: "today", start_time: "6pm", end_time: "9pm"
        Content.last.start_date.should == Chronic.parse("today 6pm")
        Content.last.end_date.should == Chronic.parse("today 9pm")
      end
      it "parses start and end date fields right with end day provided" do
        post :create, content: FactoryGirl.attributes_for(:event, start_date: nil, end_date: nil),
          start_day: "yesterday", start_time: "9pm", end_day: "next tuesday", end_time: "5pm"
        Content.last.start_date.should == Chronic.parse("yesterday 9pm")
        Content.last.end_date.should == Chronic.parse("next tuesday 5pm")
      end
    end
  end
end
