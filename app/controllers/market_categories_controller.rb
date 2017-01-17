class MarketCategoriesController < ApplicationController
  before_action :set_market_category, only: [:show, :edit, :update, :destroy]

  def index
    @market_categories = MarketCategory.all
  end

  def new
    @market_category = MarketCategory.new
    @query_modifiers = MarketCategory.query_modifier_options
  end

  def edit
    if @market_category.query?
      @search_preview = Content.search @market_category.formatted_query,
        MarketCategory.default_search_options.merge(@market_category.formatted_modifier_options)
      @market_category.update_attributes(result_count: @search_preview.total_count)
      @market_category.save!
    end
    @query_modifiers = MarketCategory.query_modifier_options
  end

  def create
    @market_category = MarketCategory.new(market_category_params)

      if @market_category.save
        #this needs to redirect back to edit to update the result count field
        redirect_to edit_market_category_path(@market_category), notice: 'Market category was successfully created.'
      else
        render action: 'new'
      end
  end

  def update
      if @market_category.update(market_category_params)
        #this needs to redirect back to edit to update the result count field
        redirect_to edit_market_category_path(@market_category), notice: 'Market category was successfully updated.'
      else
        render action: 'edit'
      end
  end

  def destroy
    @market_category.destroy
    redirect_to market_categories_path
  end

  private
    def set_market_category
      @market_category = MarketCategory.find(params[:id])
    end

    def market_category_params
      params.require(:market_category).permit(
        :name,
        :query,
        :category_image,
        :detail_page_banner,
        :featured,
        :trending, 
        :remove_category_image,
        :remove_detail_page_banner,
        :category_image_cache,
        :detail_page_banner_cache,
        :trending,
        :query_modifier)
    end
end
