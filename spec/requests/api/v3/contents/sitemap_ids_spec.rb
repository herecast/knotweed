require 'spec_helper'

RSpec.describe 'Sitemap Ids Endpoints', type: :request do
  describe 'GET /api/v3/contents/sitemap_ids' do
    let!(:org) { FactoryGirl.create :organization }
    let!(:alt_org) { FactoryGirl.create :organization }
    let!(:location) { FactoryGirl.create(:location) }

    let!(:event) do
      FactoryGirl.create :content, :event, :published, organization: org
    end
    let!(:talk) do
      FactoryGirl.create :content, :talk, :published, organization: org
    end
    let!(:market_post) do
      FactoryGirl.create :content, :market_post, :published, organization: org
    end
    let!(:news) do
      FactoryGirl.create :content, :news, :published, organization: org
    end
    let!(:comment) do
      FactoryGirl.create :content, :comment, organization: org
    end

    let(:query_params) { {} }

    subject do
      get '/api/v3/contents/sitemap_ids', params: query_params
      response_json
    end

    it 'returns the ids of the contents as expected (not events or comments by default)' do
      expect(subject[:content_ids]).to include *[talk, market_post, news].map(&:id)
      expect(subject[:content_ids]).to_not include event.id
      expect(subject[:content_ids]).to_not include comment.id
    end

    it 'allows specifying type separated by comma' do
      query_params[:type] = 'news,market'
      expect(subject[:content_ids]).to include news.id, market_post.id
      expect(subject[:content_ids]).to_not include talk.id
    end

    it 'does not include content if pubdate is null' do
      news.update pubdate: nil
      expect(subject[:content_ids]).to_not include news.id
    end

    it 'does not include content if pubdate is in the future' do
      news.update pubdate: Time.zone.now.tomorrow
      expect(subject[:content_ids]).to_not include news.id
    end

    it 'does not include content removed' do
      news.update removed: true
      expect(subject[:content_ids]).to_not include news.id
    end
  end
end
