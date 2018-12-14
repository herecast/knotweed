require 'rails_helper'

RSpec.describe Contents::FacebookScrapingsController, type: :controller do
  describe "POST #create" do
    before do
      @user = FactoryGirl.create :admin
      sign_in @user
      @content = FactoryGirl.create :content
      allow(BackgroundJob).to receive(:perform_later).and_return true
    end

    subject { post :create, params: { content_id: @content.id } }

    it "makes call to FacebookService for rescrape" do
      expect(BackgroundJob).to receive(:perform_later).with(
        'FacebookService', 'rescrape_url', @content
      )
      subject
    end
  end
end
