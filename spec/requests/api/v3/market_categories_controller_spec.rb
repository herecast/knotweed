require 'rails_helper'

RSpec.describe 'MarketCategories API Endpoints' do
  describe 'GET /api/v3/market_categories' do

    context 'when market categories exist' do
      let!(:market_categories) { FactoryGirl.create_list :market_category, 3, result_count: 25 }
      it 'returns to values for the market categories' do
        get '/api/v3/market_categories'
        expect(response_json[:market_categories].count).to eq market_categories.count

        response_json[:market_categories].each do | market_category |
          expect(market_category).to include(:id, :name, :query, :category_image, :detail_page_banner, :featured, :trending, :count)
        end
      end
    end
  end

  describe 'GET /api/v3/market_categories/:id' do
    let!(:market_category) { FactoryGirl.create :market_category }

    it 'returns the correct values for the market category' do
      get "/api/v3/market_categories/#{market_category.id}"
      expect(response_json[:market_category]).to match({
        id: market_category.id,
        name: market_category.name,
        query: market_category.query,
        category_image: market_category.category_image.url,
        detail_page_banner: market_category.detail_page_banner.url,
        featured: market_category.featured,
        trending: market_category.trending,
        count: market_category.result_count
      })
    end
  end
end
