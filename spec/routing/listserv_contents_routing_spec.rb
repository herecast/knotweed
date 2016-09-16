require "rails_helper"

RSpec.describe ListservContentsController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/listserv_contents").to route_to("listserv_contents#index")
    end

    it "routes to #new" do
      expect(:get => "/listserv_contents/new").to route_to("listserv_contents#new")
    end

    it "routes to #show" do
      expect(:get => "/listserv_contents/1").to route_to("listserv_contents#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/listserv_contents/1/edit").to route_to("listserv_contents#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/listserv_contents").to route_to("listserv_contents#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/listserv_contents/1").to route_to("listserv_contents#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/listserv_contents/1").to route_to("listserv_contents#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/listserv_contents/1").to route_to("listserv_contents#destroy", :id => "1")
    end

  end
end