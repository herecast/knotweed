require 'spec_helper'

describe BusinessLocationsController do
  before do
    @user = FactoryGirl.create :admin
    @business_location = FactoryGirl.create :business_location
    sign_in @user
  end

  describe "GET 'index'" do
    it "returns http success" do
      get 'index'
      response.should be_success
    end
  end

  describe "GET 'new'" do
    it "returns http success" do
      get 'new'
      response.should be_success
    end
  end

  describe "POST 'create'" do
    it "redirect to market_posts index on success" do
      c = FactoryGirl.create :business_location
      response.code.should eq("302")
    end
  end

  describe "GET 'edit'" do
    it "returns http success" do
      get 'edit', id: @business_location.id
      response.should be_success
    end
  end

  describe "GET 'update'" do
    it "returns http success" do
      pending 'debugging update action'
      get 'update'
      response.should be_success
    end
  end

=begin destroy action not implemented (yet, maybe never)
  describe "GET 'destroy'" do
    it "returns http success" do
      get 'destroy'
      response.should be_success
    end
  end
=end

end
