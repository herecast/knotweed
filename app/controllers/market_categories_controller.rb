class MarketCategoriesController < ApplicationController
  before_action :set_market_category, only: [:show, :edit, :update, :destroy]

  def index
    @market_categories = MarketCategory.all
  end

  def new
    @market_category = MarketCategory.new
  end

  def edit
    if @market_category.query?
      @search_preview = Content.search @market_category.query, MarketCategory.default_search_options
      @market_category.update_attributes(result_count: @search_preview.total_count)
      @market_category.save!
    end
  end

  def create
    @market_category = MarketCategory.new(market_category_params)

      if @market_category.save
        redirect_to edit_market_category_path(@market_category), notice: 'Market category was successfully created.'
      else
        render action: 'new'
      end
  end

  def update
      if @market_category.update(market_category_params)
        redirect_to market_categories_url, notice: 'Market category was successfully updated.'
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
        :trending)
    end
end
