require 'rails_helper'

RSpec.describe 'Email Receiving endpoints' do
  describe 'POST /api/v3/emails' do
    context 'not given file_uri param' do
      before do
        post '/api/v3/emails'
      end

      it 'responds with 422' do
        expect(response.status).to eql 422
      end
    end

    context 'given a file_uri param' do
      let(:post_params) { {
        file_uri: "file:///var/mail/folder/email.eml"
       } }

      subject {
        post '/api/v3/emails', post_params
      }

      it 'returns 202 Accepted' do
        subject
        expect(response.status).to eql 202
      end

      it 'creates a ReceivedEmail record' do
        expect{ subject }.to change {
          ReceivedEmail.count
        }.by(1)

        expect(ReceivedEmail.last.file_uri).to eql post_params[:file_uri]
      end

      context 'when file_uri is duplicate' do
        before do
          FactoryGirl.create :received_email, file_uri: post_params[:file_uri]
        end

        it 'responds with 422' do
          subject

          expect(response.status).to eql 422
        end
      end
    end
  end
end
