require 'spec_helper'

describe Api::EventsController, :type => :controller do

  describe "POST update" do
    before do
      @event = FactoryGirl.create :event
    end

    it "should update attributes on the event" do

      post :update, format: :json, id: @event.id, event: { event_description: "New Description" }

      response.code.should eq("200")
      @event.reload
      @event.description.should == "New Description"
    end

  end

end
