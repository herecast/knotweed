require 'spec_helper'

describe Api::V3::BusinessFeedbacksController, :type => :controller do
  before do
    @user = FactoryGirl.create :user
    api_authenticate user: @user
  end

  describe 'POST create' do
    before do
      @profile = FactoryGirl.create :business_profile
    end

    subject do
      post :create, id: @profile.id, feedback: {
        recommend: 1
      }
    end

    it 'should create a business feedback object' do
      expect{subject}.to change{ BusinessFeedback.count }.by 1
    end

    context "when user has already rated business" do
      before do
        FactoryGirl.create :business_feedback, created_by: @user, business_profile_id: @profile.id, recommend: 0
      end

      it "returns a 403 status" do
        subject
        expect(response).to have_http_status 403
      end
    end
  end

  describe 'PUT #update' do
    before do
      @business_profile = FactoryGirl.create :business_profile
      @feedback = FactoryGirl.create :business_feedback, created_by: @user, business_profile_id: @business_profile.id, recommend: 0
    end

    subject { put :update, id: @business_profile.id, feedback: { recommend: 1 } }

    it "updates user's feedback" do
      subject
      @feedback.reload
      expect(@feedback.recommend).to be true
    end

  end
end
