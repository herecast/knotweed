# frozen_string_literal: true

require 'rails_helper'

describe 'Caster Content endpoints', type: :request do
  let(:caster) { FactoryGirl.create :caster }
  let(:headers) { { 'ACCEPT' => 'application/json' } }

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
        @user = FactoryGirl.create :user
        followed_caster = FactoryGirl.create :caster
        FactoryGirl.create :caster_follow, user: @user, caster: followed_caster
        @followed_content = FactoryGirl.create :content, :news, created_by: followed_caster
        unfollowed_caster = FactoryGirl.create :caster
        FactoryGirl.create :content, :news, created_by: unfollowed_caster
      end

      let(:auth_headers) { auth_headers_for(@user) }

      subject do
        get "/api/v3/casters/#{caster.id}/contents?caster_feed=true",
          headers: auth_headers
      end

      it "returns content from followed casters" do
        subject
        content_ids = response_json[:feed_items].map{ |i| i[:content][:id] }
        expect(content_ids).to match_array [@followed_content.id]
      end
    end
  end
end
