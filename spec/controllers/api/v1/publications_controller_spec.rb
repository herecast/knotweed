require 'spec_helper'

describe Api::V1::PublicationsController do

  describe "index" do
    before do
      @publications = FactoryGirl.create_list :publication, 5
      @consumer_app = FactoryGirl.create :consumer_app
      @consumer_app.publications << @publications[0]
    end

    it "should return all publications when there is no consumer app provided" do
      get :index
      pubs = JSON.parse response.body
      pubs["publications"].count.should == 5
    end

    it "should return only pubs associated with specified consumer app" do
      get :index, consumer_app_uri: @consumer_app.uri
      pubs = JSON.parse response.body
      pubs["publications"].count.should == 1
    end

    it "should respond with 200" do
      get :index
      response.code.should eq("200")
    end
  end

  describe "show" do
    before do
      @publication = FactoryGirl.create :publication
    end

    it "should return the publication via id" do
      get :show, id: @publication.id
      response.code.should eq("200")
      response.body.should == @publication.to_json
    end

    it "should return the publication via name" do
      get :show, name: @publication.name
      response.code.should eq("200")
      response.body.should == @publication.to_json
    end

    it "should return a 500 when publication is not found" do
      get :show, name: "This publication doesn't exist"
      response.code.should eq('500')
    end
  end
  
end
