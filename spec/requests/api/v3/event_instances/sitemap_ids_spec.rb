# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'EventInstances::SitemapIds endpoints', type: :request do  
  describe 'GET /api/v3/event_instances/sitemap_ids' do
    let!(:org) { FactoryGirl.create :organization }
    let!(:alt_org) { FactoryGirl.create :organization }

    let!(:instance1) do
      FactoryGirl.create :event_instance
    end
    let!(:instance2) do
      FactoryGirl.create :event_instance
    end

    before do
      instance1.event.content.update organization: org
      instance2.event.content.update organization: org
    end

    subject do
      get '/api/v3/event_instances/sitemap_ids'
      response_json
    end

    it 'returns expected id, and content_ids for each record' do
      expect(subject[:instances]).to include({
                                               id: instance1.id,
                                               content_id: instance1.event.content.id
                                             },
                                             id: instance2.id,
                                             content_id: instance2.event.content.id)
    end

    it 'does not include instance if content is removed' do
      instance1.event.content.update removed: true
      ids = subject[:instances].map { |d| d[:id] }
      expect(ids).to_not include instance1.id
    end

    it 'does not include instance if content pubdate is null' do
      instance1.event.content.update pubdate: nil
      ids = subject[:instances].map { |d| d[:id] }
      expect(ids).to_not include instance1.id
    end

    it 'does not include instance if content pubdate is in the future' do
      instance1.event.content.update pubdate: Time.zone.now.tomorrow
      ids = subject[:instances].map { |d| d[:id] }
      expect(ids).to_not include instance1.id
    end
  end
end