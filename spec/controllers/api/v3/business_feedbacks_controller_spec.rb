require 'spec_helper'

describe Api::V3::BusinessFeedbacksController do
  before do
    @user = FactoryGirl.create :user
    api_authenticate user: @user
  end

  describe 'POST create' do
    before do
      @profile = FactoryGirl.create :business_profile
    end

    subject { post :create, id: @profile.id, feedback: {} }

    it 'should create a business feedback object' do
      expect{subject}.to change{ BusinessFeedback.count }.by 1
    end
  end
end
