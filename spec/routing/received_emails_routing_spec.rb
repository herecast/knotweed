require "rails_helper"

RSpec.describe ReceivedEmailsController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/received_emails").to route_to("received_emails#index")
    end

    it "routes to #show" do
      expect(:get => "/received_emails/1").to route_to("received_emails#show", :id => "1")
    end

  end
end
