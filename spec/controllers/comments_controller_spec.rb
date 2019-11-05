# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CommentsController, type: :controller do
  before do
    @user = FactoryGirl.create :admin
    sign_in @user
  end

  describe 'GET #index' do
    let(:params) { {} }
    subject { get :index, params: params }

    it 'returns ok status' do
      subject
      expect(response).to have_http_status :ok
    end

    context 'with reset param' do
      let(:params) { { reset: true } }

      it 'should reset the search query' do
        subject
        expect(request.session['comment_search']).to be nil
      end
    end
  end

  describe 'PUT #update' do
    before do
      @parent_content = FactoryGirl.create :content
      @comment = FactoryGirl.create :comment,
                                    deleted_at: Date.yesterday,
                                    content_id: @parent_content.id
    end

    subject { put :update, params: { id: @comment.id } }

    it 'updates deleted_at to nil' do
      expect { subject }.to change {
        @comment.reload.deleted_at
      }.to nil
    end

    it 'increase comment numbers on parent' do
      expect { subject }.to change {
        @comment.content.reload.comment_count
      }.by(1).and change {
        @comment.content.reload.commenter_count
      }.by(1)
    end
  end

  describe 'DELETE #destroy' do
    before do
      @parent_content = FactoryGirl.create :content
      @comment = FactoryGirl.create :comment,
                                    deleted_at: nil,
                                    content_id: @parent_content.id
      mailer = double(deliver_later: true)
      allow(CommentAlertMailer).to receive(:alert_parent_content_owner).and_return(
        mailer
      )
      allow(ContentRemovalAlertMailer).to receive(:content_removal_alert).and_return(
        mailer
      )
    end

    subject { delete :destroy, params: { id: @comment.id } }

    it 'updates deleted_at to current time' do
      subject
      expect(@comment.reload.deleted_at).not_to be_nil
    end

    it 'decrease comment numbers on parent' do
      expect { subject }.to change {
        @comment.content.reload.comment_count
      }.by(-1).and change {
        @comment.content.reload.commenter_count
      }.by(-1)
    end

    it 'queues email to parent content owner' do
      expect(CommentAlertMailer).to receive(:alert_parent_content_owner).with(
        @comment, @parent_content, true
      )
      subject
    end

    it 'queues email to comment creator' do
      expect(ContentRemovalAlertMailer).to receive(:content_removal_alert).with(
        @comment
      )
      subject
    end
  end
end
