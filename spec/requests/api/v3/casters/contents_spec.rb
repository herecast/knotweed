# frozen_string_literal: true

require 'rails_helper'

describe 'My Stuff endpoint', type: :request do
  pending "add some examples to (or delete) #{__FILE__}"
  # before { FactoryGirl.create :organization, name: 'Listserv' }
  # let(:user) { FactoryGirl.create :user }
  # let(:other_user) { FactoryGirl.create :user }
  # let(:headers) { { 'ACCEPT' => 'application/json' } }

  # describe '/api/v3/casters/:id/contents', elasticsearch: true do
  #   before do
  #     FactoryGirl.create :content, :news,
  #                        created_by: other_user
  #   end

  #   context 'when making my stuff request' do
  #     before do
  #       @owned_content = FactoryGirl.create :content, :news,
  #                                           created_by: user
  #       @managed_content = FactoryGirl.create :content, :event,
  #                                             created_by: user
  #       @owned_market = FactoryGirl.create :content, :market_post,
  #                                          created_by: user
  #     end

  #     context 'when no user logged in' do
  #       subject { get "/api/v3/casters/#{user.id}/contents" }

  #       it 'it returns unauthorized status' do
  #         subject
  #         expect(response).to have_http_status :unauthorized
  #       end
  #     end

  #     context 'when wrong user logged in' do
  #       let(:user_headers) { headers.merge(auth_headers_for(other_user)) }
  #       subject { get "/api/v3/casters/#{user.id}/contents", params: {}, headers: user_headers }

  #       it 'returns forbidden status' do
  #         subject
  #         expect(response).to have_http_status :forbidden
  #       end
  #     end

  #     context 'when user logged in' do
  #       let(:user_headers) { headers.merge(auth_headers_for(user)) }

  #       subject { get "/api/v3/casters/#{user.id}/contents", params: {}, headers: user_headers }

  #       it "returns only current user's content" do
  #         subject
  #         expect(response_json[:feed_items].length).to eq 3
  #         expect(response_json[:feed_items].map { |c| c[:content][:id] }).to match_array [@owned_content.id, @managed_content.id, @owned_market.id]
  #       end

  #       describe '?bookmarked' do
  #         context 'when request is bookmarked: true' do
  #           before do
  #             @non_bookmarked_content = FactoryGirl.create :content, :news
  #             @bookmarked_content = FactoryGirl.create :content, :news
  #             FactoryGirl.create :user_bookmark,
  #                                user_id: user.id,
  #                                content_id: @bookmarked_content.id
  #           end

  #           subject { get "/api/v3/casters/#{user.id}/contents?bookmarked=true", params: {}, headers: user_headers }

  #           it 'returns user bookmarked content' do
  #             subject
  #             expect(response_json[:feed_items].length).to eq 1
  #             expect(response_json[:feed_items][0][:content][:id]).to eq @bookmarked_content.id
  #           end
  #         end
  #       end
  #     end
  #   end
  # end
end
