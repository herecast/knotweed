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
      post :create, params: { id: @profile.id, feedback: {
        recommend: 1
      } }
    end

    it 'should create a business feedback object' do
      expect{subject}.to change{ BusinessFeedback.count }.by 1
    end

    context "when feedback creation fails" do
      before do
        allow_any_instance_of(BusinessFeedback).to receive(:save).and_return(false)
      end

      it "returns unprocessable entity code" do
        subject
        expect(response).to have_http_status :unprocessable_entity
      end
    end

    context "when user has already rated business" do
      before do
        content = FactoryGirl.create :business_feedback, business_profile_id: @profile.id, recommend: 0,
          created_by: @user
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
      @feedback = FactoryGirl.create :business_feedback, business_profile_id: @business_profile.id, recommend: 0,
        created_by: @user
    end

    subject { put :update, params: { id: @business_profile.id, feedback: { recommend: 1 } } }

    it "updates user's feedback" do
      expect{ subject }.to change{
        @feedback.reload.recommend
      }.to true
    end

    context "when update fails" do
      before do
        allow_any_instance_of(BusinessFeedback).to receive(:update_attributes).and_return(false)
      end

      it "returns unprocessable entity status" do
        subject
        expect(response).to have_http_status :unprocessable_entity
      end
    end

  end
end
