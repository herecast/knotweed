require 'rails_helper'

describe 'Talk', type: :request do
  let(:user) { FactoryGirl.create :user }
  let(:auth_headers) { auth_headers_for(user) }

  describe 'POST /api/v3/talk' do
    context "with valid request data" do
      before do
        ContentCategory.create(name: :talk_of_the_town)
      end

      let(:valid_params) {
        {
          title: 'Test',
          content: 'Body'
        }
      }

      subject{ post("/api/v3/talk", {talk: valid_params}, auth_headers) }

      it 'responds with 201' do
        subject
        expect(response.status).to eql 201
      end

      it 'creates a record' do
        expect{ subject }.to change{
          Comment.count
        }.by(1)
      end

      it 'returns a content_id in json' do
        # this is needed by listserv workflow
        subject
        expect(response_json[:talk][:content_id]).to eql Comment.last.content.id
      end
    end
  end
end
