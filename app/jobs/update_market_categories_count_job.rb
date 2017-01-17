require 'sidekiq/api'
class UpdateMarketCategoriesCountJob < ApplicationJob
  def perform
    categories = MarketCategory.all
    categories.each do |category|
      response = Content.search category.query,
        MarketCategory.default_search_options.merge(category.formatted_modifier_options)
      category.update_attributes(result_count: response.total_count)
      category.save!
    end
  end
end
