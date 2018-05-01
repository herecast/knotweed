
require 'rails_helper'

describe 'User Bookmarks endpoint', type: :request do
  before { FactoryGirl.create :organization, name: 'Listserv' }
  let(:organization) { FactoryGirl.create :organization }
  let(:consumer_app) { FactoryGirl.create :consumer_app, organizations: [organization] }
  let(:owning_user) { FactoryGirl.create :user }
  let(:other_user) { FactoryGirl.create :user }
  let(:headers) { {'ACCEPT' => 'application/json',
                   'Consumer-App-Uri' => consumer_app.uri
                  } }
  let(:user_headers) { headers.merge(auth_headers_for(owning_user)) }
  let(:wrong_user_headers) { headers.merge(auth_headers_for(other_user)) }

  describe "GET /api/v3/users/:user_id/bookmarks" do
    before do
      content = FactoryGirl.create :content, :news
      @bookmark = FactoryGirl.create :user_bookmark, content: content, user: owning_user
    end

    context "when incorrect user" do
      subject { get "/api/v3/users/#{owning_user.id}/bookmarks", {}, wrong_user_headers }

      it "returns forbidden status" do
        subject
        expect(response).to have_http_status :forbidden
      end
    end

    context "when correct user" do
      subject { get "/api/v3/users/#{owning_user.id}/bookmarks", {}, user_headers }

      it "returns user's bookmarks" do
        subject
        expect(response_json[:bookmarks].length).to eq 1
        expect(response_json[:bookmarks][0][:id]).to eq @bookmark.id
      end
    end
  end

  describe "POST /api/v3/users/:user_id/bookmarks" do
    let(:bookmarked_content) { FactoryGirl.create :content, :news }

    context "when incorrect user" do
      subject { post "/api/v3/users/#{owning_user.id}/bookmarks", { bookmark: { content_id: bookmarked_content.id } }, wrong_user_headers }

      it "returns forbidden status" do
        subject
        expect(response).to have_http_status :forbidden
      end
    end

    context "when correct user" do
      subject { post "/api/v3/users/#{owning_user.id}/bookmarks", { bookmark: { content_id: bookmarked_content.id } }, user_headers }

      it "creates a UserBookmark record" do
        expect{ subject }.to change{
          owning_user.reload.user_bookmarks.length
        }.by 1
      end
    end
  end

  describe "PUT /api/v3/users/:user_id/bookmarks/:id" do
    before do
      @bookmarked_content = FactoryGirl.create :content, :news
      @bookmark = owning_user.user_bookmarks.create(content_id: @bookmarked_content.id)
    end

    let(:bookmark_params) { { bookmark: { read: true } } }

    context "when incorrect user" do
      subject { put "/api/v3/users/#{owning_user.id}/bookmarks/#{@bookmarked_content.id}", bookmark_params, wrong_user_headers }

      it "returns forbidden status" do
        subject
        expect(response).to have_http_status :forbidden
      end
    end

    context "with correct user" do
      subject { put "/api/v3/users/#{owning_user.id}/bookmarks/#{@bookmark.id}", bookmark_params, user_headers }

      it "updates user_bookmark" do
        expect{ subject }.to change{
          @bookmark.reload.read
        }.to true
      end
    end
  end

  describe "DELETE /api/v3/users/:user_id/bookmarks/:id" do
    before do
      bookmarked_content = FactoryGirl.create :content, :news
      @bookmark = owning_user.user_bookmarks.create(content_id: bookmarked_content.id)
    end

    context "with incorrect user" do
      subject { delete "/api/v3/users/#{owning_user.id}/bookmarks/#{@bookmark.id}", {}, wrong_user_headers }

      it "returns forbidden status" do
        subject
        expect(response).to have_http_status :forbidden
      end
    end

    context "with correct user" do
      subject { delete "/api/v3/users/#{owning_user.id}/bookmarks/#{@bookmark.id}", {}, user_headers }

      it "creates a UserBookmark record" do
        expect{ subject }.to change{
          @bookmark.reload.deleted_at
        }
      end
    end
  end
end