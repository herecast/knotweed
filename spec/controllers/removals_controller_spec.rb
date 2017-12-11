require 'spec_helper'

RSpec.describe Contents::RemovalsController, type: :controller do

  describe "POST #create" do
    before do
      @user = FactoryGirl.create :admin
      sign_in @user
      @content = FactoryGirl.create :content, removed: false
      allow(BackgroundJob).to receive(:perform_later).and_return true
    end

    subject { post :create, content_id: @content.id, type: 'contents' }

    it "updates Content.removed to true" do
      expect{ subject }.to change{
        @content.reload.removed
      }.to true
    end

    it "makes call to FacebookService for rescrape" do
      expect(BackgroundJob).to receive(:perform_later).with(
        'FacebookService', 'rescrape_url', @content
      )
      subject
    end
  end

  describe "DELETE #destroy" do
    before do
      @user = FactoryGirl.create :admin
      sign_in @user
      @content = FactoryGirl.create :content, removed: true
      allow(BackgroundJob).to receive(:perform_later).and_return true
    end

    subject { delete :destroy, content_id: @content.id, type: 'contents' }

    it "updates Content.removed to false" do
      expect{ subject }.to change{
        @content.reload.removed
      }.to false
    end

    it "makes call to FacebookService for rescrape" do
      expect(BackgroundJob).to receive(:perform_later).with(
        'FacebookService', 'rescrape_url', @content
      )
      subject
    end
  end
end