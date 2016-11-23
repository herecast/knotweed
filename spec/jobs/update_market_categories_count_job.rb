require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe UpdateMarketCategoriesCountJob do

  describe 'perform' do

    before do
      FactoryGirl.create_list :market_category, 2, query: 'free', result_count: 0
      response = OpenStruct.new(total_count: 10)
      allow(Content).to receive(:search).and_return(response)
      allow(MarketCategory).to receive(:default_search_options).and_return({})
    end
    
    it 'updates the count for all market categories' do
      subject.perform
      market_categories = MarketCategory.all
      market_categories.each do |category|
        expect(category.result_count).to eq 10
      end
    end
  end

end
