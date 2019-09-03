# frozen_string_literal: true

require 'rails_helper'

describe 'User Bookmarks endpoint', type: :request, elasticsearch: true do
  before { FactoryGirl.create :organization, name: 'Listserv' }
  let(:organization) { FactoryGirl.create :organization }
  let(:owning_user) { FactoryGirl.create :user }
  let(:other_user) { FactoryGirl.create :user }
  let(:headers) { { 'ACCEPT' => 'application/json' } }
  let(:user_headers) { headers.merge(auth_headers_for(owning_user)) }
  let(:wrong_user_headers) { headers.merge(auth_headers_for(other_user)) }

  describe 'GET /api/v3/users/:user_id/bookmarks' do
    before do
      content = FactoryGirl.create :content, :news
      @bookmark = FactoryGirl.create :user_bookmark, content: content, user: owning_user
    end

    context 'when correct user' do
      subject { get "/api/v3/users/#{owning_user.id}/bookmarks", params: {}, headers: user_headers }

      it "returns user's bookmarks" do
        subject
        expect(response_json[:bookmarks].length).to eq 1
        expect(response_json[:bookmarks][0][:id]).to eq @bookmark.id
      end
    end
  end

  describe 'POST /api/v3/users/:user_id/bookmarks' do
    let(:bookmarked_content) { FactoryGirl.create :content, :news }

    context 'when correct user' do
      subject { post "/api/v3/users/#{owning_user.id}/bookmarks", params: { bookmark: { content_id: bookmarked_content.id } }, headers: user_headers }

      it 'creates a UserBookmark record' do
        expect { subject }.to change {
          owning_user.reload.user_bookmarks.length
        }.by 1
      end
    end

    context 'without valid content' do
      subject { post "/api/v3/users/#{owning_user.id}/bookmarks", params: { bookmark: { read: false } }, headers: user_headers }

      it 'responds with bad request' do
        subject
        expect(response).to be_a_bad_request
      end
    end
  end

  describe 'PUT /api/v3/users/:user_id/bookmarks/:id' do
    before do
      @bookmarked_content = FactoryGirl.create :content, :news
      @bookmark = owning_user.user_bookmarks.create(content_id: @bookmarked_content.id)
    end

    let(:bookmark_params) { { bookmark: { read: true } } }

    context 'when incorrect user' do
      subject { put "/api/v3/users/#{owning_user.id}/bookmarks/#{@bookmark.id}", params: bookmark_params, headers: wrong_user_headers }

      it 'returns forbidden status' do
        subject
        expect(response).to have_http_status :forbidden
      end
    end

    context 'with correct user' do
      subject { put "/api/v3/users/#{owning_user.id}/bookmarks/#{@bookmark.id}", params: bookmark_params, headers: user_headers }

      it 'updates user_bookmark' do
        expect { subject }.to change {
          @bookmark.reload.read
        }.to true
      end

      context 'without valid content' do
        let(:invalid_id) { (Content.maximum(:id) || 0) + 1 }
        subject { post "/api/v3/users/#{owning_user.id}/bookmarks", params: { bookmark: { content_id: invalid_id } }, headers: user_headers }

        it 'responds with bad request' do
          subject
          expect(response).to be_a_bad_request
        end
      end
    end
  end

  describe 'DELETE /api/v3/users/:user_id/bookmarks/:id' do
    before do
      bookmarked_content = FactoryGirl.create :content, :news
      @bookmark = owning_user.user_bookmarks.create(content_id: bookmarked_content.id)
    end

    context 'with incorrect user' do
      subject { delete "/api/v3/users/#{owning_user.id}/bookmarks/#{@bookmark.id}", params: {}, headers: wrong_user_headers }

      it 'returns forbidden status' do
        subject
        expect(response).to have_http_status :forbidden
      end
    end

    context 'with correct user' do
      subject { delete "/api/v3/users/#{owning_user.id}/bookmarks/#{@bookmark.id}", params: {}, headers: user_headers }

      it 'creates a UserBookmark record' do
        expect { subject }.to change {
          @bookmark.reload.deleted_at
        }
      end
    end
  end
end
