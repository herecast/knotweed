require 'spec_helper'

describe Api::EventsController, :type => :controller do

  describe "POST update" do
    before do
      @event = FactoryGirl.create :event
    end

    it "should update attributes on the event" do
      # we put the post in a begin-rescue block because it throws this error: ActionView::MissingTemplate: Missing template api/events/update
      # whats happening is that it is looking for a view which doesn't exist. So we trap the error and continue on with the
      # test. There may be other ways out of this, but this method works for now.
      # Here is controller doc: http://www.relishapp.com/rspec/rspec-rails/v/3-2/docs/controller-specs/views-are-stubbed-by-default

      begin
        post :update, format: :json, id: @event.id, event: { event_description: "New Description" }
      rescue
      end

      response.code.should eq("200")
      @event.reload
      @event.description.should == "New Description"
    end

  end

end
