# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Organizations::SitemapIds Endpoints', type: :request do
  describe 'GET /api/v3/organizations/sitemap_ids' do
    let!(:org_biz) do
      FactoryGirl.create :organization,
                         org_type: 'Business',
                         biz_feed_active: true
    end
    let!(:org_publisher) do
      FactoryGirl.create :organization,
                         org_type: 'Publisher',
                         can_publish_news: true
    end
    let!(:org_blog) do
      FactoryGirl.create :organization,
                         org_type: 'Blog',
                         can_publish_news: true
    end
    let!(:org_publication) do
      FactoryGirl.create :organization,
                         org_type: 'Publication',
                         can_publish_news: true
    end

    subject do
      get '/api/v3/organizations/sitemap_ids'
      response_json
    end

    it 'includes expected ids' do
      expect(subject[:organization_ids]).to include *[org_biz, org_publisher, org_blog, org_publication].map(&:id)
    end

    it 'does not include business with biz_feed_active=false' do
      org_biz.update biz_feed_active: false
      expect(subject[:organization_ids]).to_not include org_biz.id
    end

    it 'does not include publishing organizations with can_publish_news=false' do
      publisher_orgs = [org_publisher, org_blog, org_publication]
      publisher_orgs.each { |org| org.update can_publish_news: false }

      expect(subject[:organization_ids]).to_not include *publisher_orgs.map(&:id)
    end
  end
end
