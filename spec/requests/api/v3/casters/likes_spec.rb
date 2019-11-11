# frozen_string_literal: true

require 'rails_helper'

describe 'Caster Likes endpoints', type: :request, elasticsearch: true do
  before { FactoryGirl.create :organization, name: 'Listserv' }
  let(:owning_user) { FactoryGirl.create :user }
  let(:other_user) { FactoryGirl.create :user }
  let(:headers) { { 'ACCEPT' => 'application/json' } }
  let(:user_headers) { headers.merge(auth_headers_for(owning_user)) }
  let(:wrong_user_headers) { headers.merge(auth_headers_for(other_user)) }

  describe 'GET /api/v3/casters/:caster_id/likes' do
    before do
      content = FactoryGirl.create :content, :news
      @like = FactoryGirl.create :like, content: content, user: owning_user
    end

    context 'when correct user' do
      subject { get "/api/v3/casters/#{owning_user.id}/likes", params: {}, headers: user_headers }

      it "returns user's likes" do
        subject
        expect(response_json[:likes].length).to eq 1
        expect(response_json[:likes][0][:id]).to eq @like.id
      end
    end
  end

  describe 'POST /api/v3/casters/:caster_id/likes' do
    let(:liked_content) { FactoryGirl.create :content, :news }

    context 'when correct user' do
      subject { post "/api/v3/casters/#{owning_user.id}/likes", params: { like: { content_id: liked_content.id } }, headers: user_headers }

      it 'creates a Like record' do
        expect { subject }.to change {
          owning_user.reload.likes.length
        }.by 1
      end
    end

    context 'without valid content' do
      subject { post "/api/v3/casters/#{owning_user.id}/likes", params: { like: { other_stuff: 1} }, headers: user_headers }

      it 'responds with bad request' do
        subject
        expect(response).to be_a_bad_request
      end
    end
  end

  describe 'PUT /api/v3/casters/:user_id/likes/:id' do
    before do
      @liked_content = FactoryGirl.create :content, :news
      @like = owning_user.likes.create(content_id: @liked_content.id)
    end

    let(:like_params) { { like: {} } }

    context 'when incorrect user' do
      subject { put "/api/v3/casters/#{owning_user.id}/likes/#{@like.id}", params: like_params, headers: wrong_user_headers }

      it 'returns forbidden status' do
        subject
        expect(response).to have_http_status :forbidden
      end
    end

    context 'with correct user' do
      let(:new_content) { FactoryGirl.create :content, :news }
      let(:like_params) { { like: { content_id: new_content.id } } }

      subject { put "/api/v3/casters/#{owning_user.id}/likes/#{@like.id}", params: like_params, headers: user_headers }

      it 'updates like' do
        expect { subject }.to change {
          @like.reload.content_id
        }.to new_content.id
      end

      context 'without valid content' do
        let(:invalid_id) { (Content.maximum(:id) || 0) + 1 }
        subject { post "/api/v3/casters/#{owning_user.id}/likes", params: { like: { content_id: invalid_id } }, headers: user_headers }

        it 'responds with bad request' do
          subject
          expect(response).to be_a_bad_request
        end
      end
    end
  end

  describe 'DELETE /api/v3/casters/:caster_id/likes/:id' do
    before do
      liked_content = FactoryGirl.create :content, :news
      @like = owning_user.likes.create(content_id: liked_content.id)
    end

    context 'with incorrect user' do
      subject { delete "/api/v3/casters/#{owning_user.id}/likes/#{@like.id}", params: {}, headers: wrong_user_headers }

      it 'returns forbidden status' do
        subject
        expect(response).to have_http_status :forbidden
      end
    end

    context 'with correct user' do
      subject { delete "/api/v3/casters/#{owning_user.id}/likes/#{@like.id}", params: {}, headers: user_headers }

      it 'creates a Like record' do
        expect { subject }.to change {
          @like.reload.deleted_at
        }
      end
    end
  end
end
