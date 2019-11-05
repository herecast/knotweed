# frozen_string_literal: true

require 'spec_helper'
require 'json'

describe Api::V3::CommentsController, type: :controller do
  describe 'GET index' do
    it 'should fail without content_id' do
      get :index, format: :json
      expect(response.status).to eql 404
    end

    describe 'given content_id' do
      let(:content) { FactoryGirl.create :content }
      let!(:comment) { FactoryGirl.create :comment, content: content }

      subject { get :index, format: :json, params: { content_id: content.id } }

      it 'should return the coments associated' do
        subject
        expect(assigns(:comments)).to match_array([comment])
      end

      context 'when content is removed' do
        let(:content) { FactoryGirl.create :content, removed: true }

        it 'returns empty array' do
          subject
          expect(assigns(:comments)).to eq(nil)
        end
      end
    end

    describe 'ordered by pubdate DESC' do
      let(:content) { FactoryGirl.create :content }
      let!(:comment1) { FactoryGirl.create :comment, content: content,
                        pubdate: 1.week.ago }
      let!(:comment2) { FactoryGirl.create :comment, content: content,
                        pubdate: 2.weeks.ago }
      let!(:comment3) { FactoryGirl.create :comment, content: content,
                        pubdate: 3.weeks.ago }
      subject! { get :index, format: :json, params: { content_id: content.id } }

      it 'should return ordered results' do
        expect(assigns(:comments)).to match_array([comment1, comment2, comment3])
      end
    end
  end

  describe 'POST create' do
    let(:content_user) { FactoryGirl.create :user, receive_comment_alerts: true }
    let(:comment_user) { FactoryGirl.create :user }
    let(:content) { FactoryGirl.create :content, created_by: content_user }

    before { api_authenticate user: comment_user }

    subject { post :create, params: { comment: { content: 'fake', parent_id: content.id } } }

    context 'should not allow creation if user unauthorized' do
      before { api_authenticate success: false }
      it do
        subject
        expect(response.code).to eq('401')
        expect(Comment.count).to eq(0)
      end
    end

    it 'fires CommentAlert process to send email alert' do
      expect(CommentAlert).to receive(:call).with(an_instance_of(Comment))
      subject
    end

    it 'enques the notification email' do
      expect { subject }.to change { ActiveJob::Base.queue_adapter.enqueued_jobs.size }.by(1)
    end

    context 'when comment contains HTML tags' do
      let(:allowed_content) { 'Hi this is allowed' }

      let(:comment_params) do
        {
          content: "<div><p><span style='color: red'>#{allowed_content}</span></p></div>",
          parent_content_id: content.id
        }
      end

      subject { post :create, params: { comment: comment_params } }

      it 'strips HTML tags from comment' do
        subject
        expect(Comment.last.raw_content).to eq allowed_content
      end
    end
  end

end
