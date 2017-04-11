require "rails_helper"

RSpec.describe UsersController, type: :routing do
  describe "routing" do
    it "routes to #create" do
      expect(:post => "/admin/users/admin-create").to route_to("users#create")
    end

    it "routes to #update" do
      expect(:put => "/admin/users/1/admin-update").to route_to("users#update", id: "1")
    end

    it "routes temp_user to #destroy" do
      expect(:delete => "/admin/temp_user/1").to route_to("temp_user_capture#destroy", id: "1")
    end
  end
end
