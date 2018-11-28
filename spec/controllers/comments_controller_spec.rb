require 'spec_helper'

RSpec.describe CommentsController, type: :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  describe "GET #index" do
    subject { get :index }

    it "returns ok status" do
      subject
      expect(response).to have_http_status :ok
    end
  end

  describe "PUT #update" do
    before do
      @parent_content = FactoryGirl.create :content
      @comment = FactoryGirl.create :comment,
        deleted_at: Date.yesterday,
        parent_id: @parent_content.id
    end

    subject { put :update, params: { id: @comment.content.id } }

    it "updates deleted_at to nil" do
      expect{ subject }.to change{
        @comment.content.reload.deleted_at
      }.to nil
    end

    it "increase comment numbers on parent" do
      expect{ subject }.to change{
        @comment.parent.reload.comment_count
      }.by(1).and change{
        @comment.parent.reload.commenter_count
      }.by(1)
    end
  end

  describe "DELETE #destroy" do
    before do
      @parent_content = FactoryGirl.create :content
      @comment = FactoryGirl.create :comment,
        deleted_at: nil,
        parent_id: @parent_content.id
      mailer = double(deliver_later: true)
      allow(CommentAlertMailer).to receive(:alert_parent_content_owner).and_return(
        mailer
      )
    end

    subject { delete :destroy, params: { id: @comment.content.id } }

    it "updates deleted_at to current time" do
      subject
      expect(@comment.content.reload.deleted_at).not_to be_nil
    end

    it "decrease comment numbers on parent" do
      expect{ subject }.to change{
        @comment.parent.reload.comment_count
      }.by(-1).and change{
        @comment.parent.reload.commenter_count
      }.by(-1)
    end


    it "queues email to content owner" do
      expect(CommentAlertMailer).to receive(:alert_parent_content_owner).with(
        @comment.content, @parent_content, true
      )
      subject
    end
  end
end
