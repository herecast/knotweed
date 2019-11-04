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
  end
end
