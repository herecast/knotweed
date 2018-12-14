# frozen_string_literal: true

require 'rails_helper'

describe 'My Stuff endpoint', type: :request do
  before { FactoryGirl.create :organization, name: 'Listserv' }
  let(:user) { FactoryGirl.create :user }
  let(:other_user) { FactoryGirl.create :user }
  let(:standard_org) { FactoryGirl.create :organization, standard_ugc_org: true }
  let(:managed_org) { FactoryGirl.create :organization }
  let(:headers) { { 'ACCEPT' => 'application/json' } }

  describe '/api/v3/users/:id/contents', elasticsearch: true do
    before do
      FactoryGirl.create :content, :news,
                         created_by: other_user,
                         organization: standard_org
      user.add_role('manager', managed_org)
    end

    context 'when making my stuff request' do
      before do
        @owned_content = FactoryGirl.create :content, :news,
                                            created_by: user,
                                            organization: standard_org
        @managed_content = FactoryGirl.create :content, :event,
                                              created_by: user,
                                              organization: managed_org
      end

      context 'when no user logged in' do
        subject { get "/api/v3/users/#{user.id}/contents" }

        it 'it returns unauthorized status' do
          subject
          expect(response).to have_http_status :unauthorized
        end
      end

      context 'when wrong user logged in' do
        let(:user_headers) { headers.merge(auth_headers_for(other_user)) }
        subject { get "/api/v3/users/#{user.id}/contents", params: {}, headers: user_headers }

        it 'returns forbidden status' do
          subject
          expect(response).to have_http_status :forbidden
        end
      end

      context 'when user logged in' do
        let(:user_headers) { headers.merge(auth_headers_for(user)) }

        subject { get "/api/v3/users/#{user.id}/contents", params: {}, headers: user_headers }

        it "returns only current user's content" do
          subject
          expect(response_json[:feed_items].length).to eq 2
          expect(response_json[:feed_items].map { |c| c[:content][:id] }).to match_array [@owned_content.id, @managed_content.id]
        end

        describe '?organization_id' do
          context 'when request includes organization_id=false' do
            subject { get "/api/v3/users/#{user.id}/contents?organization_id=false", params: {}, headers: user_headers }

            it 'returns content connected to standard_ugc_org' do
              subject
              expect(response_json[:feed_items].length).to eq 1
              expect(response_json[:feed_items][0][:content][:id]).to eq @owned_content.id
            end
          end

          context 'when request includes organization_id for managed organization' do
            subject { get "/api/v3/users/#{user.id}/contents?organization_id=#{managed_org.id}", params: {}, headers: user_headers }

            it 'returns content connected to the managed org and created_by User' do
              subject
              expect(response_json[:feed_items].length).to eq 1
              expect(response_json[:feed_items][0][:content][:id]).to eq @managed_content.id
            end
          end
        end

        describe '?bookmarked' do
          context 'when request is bookmarked: true' do
            before do
              @non_bookmarked_content = FactoryGirl.create :content, :news
              @bookmarked_content = FactoryGirl.create :content, :news
              FactoryGirl.create :user_bookmark,
                                 user_id: user.id,
                                 content_id: @bookmarked_content.id
            end

            subject { get "/api/v3/users/#{user.id}/contents?bookmarked=true", params: {}, headers: user_headers }

            it 'returns user bookmarked content' do
              subject
              expect(response_json[:feed_items].length).to eq 1
              expect(response_json[:feed_items][0][:content][:id]).to eq @bookmarked_content.id
            end
          end
        end
      end
    end
  end
end
