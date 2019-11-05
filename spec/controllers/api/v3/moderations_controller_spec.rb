# frozen_string_literal: true

require 'spec_helper'

describe Api::V3::ModerationsController, type: :controller do
  let(:user) { FactoryGirl.create :user }
  before { api_authenticate user: user }

  describe 'POST create' do
    subject { post :create, params: params, format: :json }

    context 'with unrecognized `content_type` param' do
      let(:params) { { content_type: 'fake' } }

      it 'should respond with 404' do
        subject
        expect(response.code).to eq('404')
      end
    end

    context 'for Comment record' do
      let(:comment) { FactoryGirl.create :comment }
      let(:params) { { content_type: 'comment', id: comment.id, flag_type: 'whatever' } }
      let(:mailer) { double(deliver_later: true) }

      it 'should trigger ModerationMailer' do
        expect(ModerationMailer).to receive(:send_moderation_flag_v2).
          with(comment, params[:flag_type], user).and_return(mailer)
        subject
      end
    end

    context 'for Content record' do
      let(:content) { FactoryGirl.create :content }
      let(:params) { { content_type: 'content', id: content.id, flag_type: 'whatever' } }
      let(:mailer) { double(deliver_later: true) }

      it 'should trigger ModerationMailer' do
        expect(ModerationMailer).to receive(:send_moderation_flag_v2).
          with(content, params[:flag_type], user).and_return(mailer)
        subject
      end
    end
  end
end
