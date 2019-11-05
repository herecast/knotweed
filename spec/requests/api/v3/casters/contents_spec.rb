# frozen_string_literal: true

require 'rails_helper'

describe 'Caster Content endpoints', type: :request do
  let(:caster) { FactoryGirl.create :caster }
  let(:params) { {} }
  let(:user) { FactoryGirl.create :user }
  let(:headers) { auth_headers_for(user) }

  subject { get "/api/v3/casters/#{user.id}/contents", params: params, headers: headers }

  describe 'comments', elasticsearch: true do
    let(:other_user) { FactoryGirl.create :user }
    let(:content) { FactoryGirl.create :content, :news, created_by: other_user }
    # just to test that the following are not included
    let(:other_content) { FactoryGirl.create :content, :news, created_by: user }
    let!(:other_comment) { FactoryGirl.create :comment, content: other_content, created_by: other_user }
    let!(:comment) { FactoryGirl.create :comment, content: content, created_by: user }
    let(:params) { { commented: true } }
    it 'should return content that the user commented on' do
      subject
      expect(response_json[:feed_items].map{ |c| c[:content][:id] }).to match_array [content.id]
    end
  end

  describe '/api/v3/casters/:id/contents', elasticsearch: true do
    context "when call is standard" do
      before do
        @length = 5
        FactoryGirl.create_list :content, @length, :news, created_by: caster
      end

      subject { get "/api/v3/casters/#{caster.id}/contents" }

      it "should return all caster's contents" do
        subject
        expect(response_json[:feed_items].count).to eq @length
      end
    end

    context "?caster_feed=true" do
      before do
        followed_caster = FactoryGirl.create :caster
        FactoryGirl.create :caster_follow, user: user, caster: followed_caster
        @followed_content = FactoryGirl.create :content, :news, created_by: followed_caster
        unfollowed_caster = FactoryGirl.create :caster
        FactoryGirl.create :content, :news, created_by: unfollowed_caster
      end

      let(:params) { { caster_feed: true } }

      it "returns content from followed casters" do
        subject
        content_ids = response_json[:feed_items].map{ |i| i[:content][:id] }
        expect(content_ids).to match_array [@followed_content.id]
      end
    end
  end
end
