require 'spec_helper'

RSpec.describe TempUserCaptureController, type: :controller do
  before do
    user = FactoryGirl.create :admin
    sign_in user
    @temp_user_capture = FactoryGirl.create :temp_user_capture
  end

  describe "GET #index" do
    subject { get :index }

    it "returns ok status" do
      subject
      expect(response).to have_http_status :ok
    end
  end

  describe "DELETE #destroy" do
    subject { delete :destroy, id: @temp_user_capture }

    it "removes temp_user_capture" do
      expect{ subject }.to change{
        TempUserCapture.count
      }.by -1
    end
  end
end