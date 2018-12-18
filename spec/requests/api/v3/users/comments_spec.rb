# frozen_string_literal: true

require 'rails_helper'

describe 'User Comments endpoint', type: :request do
  before { FactoryGirl.create :organization, name: 'Listserv' }
  let(:user) { FactoryGirl.create :user }
  let(:other_user) { FactoryGirl.create :user }
  let(:standard_org) { FactoryGirl.create :organization, standard_ugc_org: true }
  let(:headers) { { 'ACCEPT' => 'application/json' } }

  describe '/api/v3/users/:id/comments', elasticsearch: true do
    before do
      FactoryGirl.create :content, :comment,
                         created_by: other_user,
                         organization: standard_org
      @comment_text = 'Vader is innocent!'
      @owned_comment = FactoryGirl.create :content, :comment,
                                          created_by: user,
                                          organization: standard_org,
                                          raw_content: @comment_text
    end

    context 'when no user logged in' do
      subject { get "/api/v3/users/#{user.id}/comments" }

      it 'it returns unauthorized status' do
        subject
        expect(response).to have_http_status :unauthorized
      end
    end

    context 'when user logged in' do
      let(:user_headers) { headers.merge(auth_headers_for(user)) }

      subject { get "/api/v3/users/#{user.id}/comments", params: {}, headers: user_headers }

      it "returns only current user's comments" do
        subject
        expect(response_json[:comments].length).to eq 1
        expect(response_json[:comments][0][:id]).to eq @owned_comment.id
      end
    end

    context 'when wrong user logged in' do
      let(:user_headers) { headers.merge(auth_headers_for(other_user)) }

      subject { get "/api/v3/users/#{user.id}/comments", params: {}, headers: user_headers }

      it 'returns forbidden status' do
        subject
        expect(response).to have_http_status :forbidden
      end
    end
  end
end
