require 'spec_helper'

describe Api::MessagesController do

  describe "GET 'index'" do

    before do
      @m1 = FactoryGirl.create :message, controller: "application"
      @m2 = FactoryGirl.create :message, controller: "events"
      @m3 = FactoryGirl.create :message, controller: "events", action: "index"
    end

    it "returns http success" do
      get :index
      response.should be_success
    end

    it "returns active messages in JSON format" do
      get :index
      response.body.should == { messages: [@m1, @m2, @m3] }.to_json
    end

    it "allows filtering by controller" do
      get :index, messages: { controller: "application" }
      response.body.should == { messages: [@m1] }.to_json
    end

    it "allows filtering by controller and action" do
      get :index, messages: { controller: "events", action: "index" }
      response.body.should == { messages: [@m3] }.to_json
    end

  end

end
