# frozen_string_literal: true

require 'rails_helper'

describe 'Caster SitemapIds endpoints', type: :request do
  describe 'GET /api/v3/casters/sitemap_ids' do
    before do
      @caster_one = FactoryGirl.create :caster
      @caster_two = FactoryGirl.create :caster
      archived_caster = FactoryGirl.create :caster, archived: true
    end

    subject { get '/api/v3/casters/sitemap_ids' }

    it "returns non-archived Caster handles" do
      expected_handles = [@caster_one.handle, @caster_two.handle]
      subject
      expect(response_json[:handles]).to match_array expected_handles
    end
  end
end