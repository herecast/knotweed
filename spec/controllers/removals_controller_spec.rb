require 'spec_helper'

RSpec.describe Contents::RemovalsController, type: :controller do

  describe "POST #create" do
    before do
      @user = FactoryGirl.create :admin
      sign_in @user
      @content = FactoryGirl.create :content, removed: false
    end

    subject { post :create, content_id: @content.id, type: 'contents' }

    it "updates Content.removed to true" do
      expect{ subject }.to change{
        @content.reload.removed
      }.to true
    end
  end

  describe "DELETE #destroy" do
    before do
      @user = FactoryGirl.create :admin
      sign_in @user
      @content = FactoryGirl.create :content, removed: true
    end

    subject { delete :destroy, content_id: @content.id, type: 'contents' }

    it "updates Content.removed to false" do
      expect{ subject }.to change{
        @content.reload.removed
      }.to false
    end
  end
end