require 'spec_helper'

describe Api::PublicationsController do

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
